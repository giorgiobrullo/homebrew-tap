class TailscalePatched < Formula
  desc "Tailscale CLI daemon with a toggle for public-source inbound routing"
  homepage "https://tailscale.com"
  url "https://github.com/tailscale/tailscale.git",
      tag:      "v1.96.4",
      revision: "41cb72f27119f95b859335f3ffc3434d6ca55e23"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  depends_on "go" => :build

  conflicts_with "tailscale", because: "both install tailscale and tailscaled binaries"
  conflicts_with cask: "tailscale-app"

  patch :DATA

  def install
    vars = Utils.safe_popen_read("./build_dist.sh", "shellvars")
    ldflags = %W[
      -s -w
      -X tailscale.com/version.longStamp=#{vars.match(/VERSION_LONG="(.*)"/)[1]}-patched
      -X tailscale.com/version.shortStamp=#{vars.match(/VERSION_SHORT="(.*)"/)[1]}-patched
      -X tailscale.com/version.gitCommitStamp=#{vars.match(/VERSION_GIT_HASH="(.*)"/)[1]}
    ]

    system "go", "build", *std_go_args(ldflags:, output: bin/"tailscale-patched"), "./cmd/tailscale"
    system "go", "build", *std_go_args(ldflags:, output: bin/"tailscaled"), "./cmd/tailscaled"
  end

  def post_install
    (var/"lib/tailscale").mkpath
    chmod 0700, var/"lib/tailscale"
  end

  service do
    run [opt_bin/"tailscaled", "--statedir=#{var}/lib/tailscale"]
    keep_alive true
    require_root true
    log_path var/"log/tailscale-patched.log"
    error_log_path var/"log/tailscale-patched.log"
  end

  def caveats
    <<~EOS
      This is a patched Tailscale build for personal routed-prefix/BGP setups.
      It adds a per-profile preference that can bypass the inbound ACL packet
      filter while leaving the default upstream behavior unchanged:

        tailscale-patched set --allow-public-inbound=true
        tailscale-patched set --allow-public-inbound=false

      The setting is stored in Tailscale prefs for the active profile/network.
      It is intentionally off by default. Enabling it allows packets received
      from tailnet peers to reach this node even when the original packet source
      is not a tailnet IP, preserving public client source IPs in NETMAP-style
      routed-prefix deployments.

      Run the daemon as root so macOS can create a real utun device:

        sudo brew services start tailscale-patched

      The CLI is installed as tailscale-patched so it can coexist with the
      official Tailscale app's tailscale wrapper. Do not run both daemons at
      the same time; quit/disable the official app before starting this service.
    EOS
  end

  test do
    version_text = shell_output("#{bin}/tailscale-patched version")
    assert_match version.to_s, version_text
    assert_match(/commit: [a-f0-9]{40}/, version_text)
    assert_match "--allow-public-inbound", shell_output("#{bin}/tailscale-patched set --help")

    spawn bin/"tailscaled", "-tun=userspace-networking", "-socket=#{testpath}/tailscaled.socket",
                            "-statedir=#{testpath}/state"
    sleep 2
    status = shell_output("#{bin}/tailscale-patched --socket=#{testpath}/tailscaled.socket status", 1)
    assert_match "Logged out.", status
  end
end

__END__
diff --git a/cmd/tailscale/cli/set.go b/cmd/tailscale/cli/set.go
index 22d7864..9df38d4 100644
--- a/cmd/tailscale/cli/set.go
+++ b/cmd/tailscale/cli/set.go
@@ -50,6 +50,7 @@ type setArgsT struct {
 	exitNodeIP                 string
 	exitNodeAllowLANAccess     bool
 	shieldsUp                  bool
+	allowPublicInbound         bool
 	runSSH                     bool
 	runWebClient               bool
 	hostname                   string
@@ -80,6 +81,7 @@ func newSetFlagSet(goos string, setArgs *setArgsT) *flag.FlagSet {
 	setf.StringVar(&setArgs.exitNodeIP, "exit-node", "", "Tailscale exit node (IP, base name, or auto:any) for internet traffic, or empty string to not use an exit node")
 	setf.BoolVar(&setArgs.exitNodeAllowLANAccess, "exit-node-allow-lan-access", false, "Allow direct access to the local network when routing traffic via an exit node")
 	setf.BoolVar(&setArgs.shieldsUp, "shields-up", false, "don't allow incoming connections")
+	setf.BoolVar(&setArgs.allowPublicInbound, "allow-public-inbound", false, "allow inbound packets with non-tailnet source IPs by bypassing the inbound ACL packet filter")
 	setf.BoolVar(&setArgs.runSSH, "ssh", false, "run an SSH server, permitting access per tailnet admin's declared policy")
 	setf.StringVar(&setArgs.hostname, "hostname", "", "hostname to use instead of the one provided by the OS")
 	setf.StringVar(&setArgs.advertiseRoutes, "advertise-routes", "", "routes to advertise to other nodes (comma-separated, e.g. \"10.0.0.0/8,192.168.0.0/24\") or empty string to not advertise routes")
@@ -149,6 +151,7 @@ func runSet(ctx context.Context, args []string) (retErr error) {
 			CorpDNS:                setArgs.acceptDNS,
 			ExitNodeAllowLANAccess: setArgs.exitNodeAllowLANAccess,
 			ShieldsUp:              setArgs.shieldsUp,
+			AllowPublicInbound:     setArgs.allowPublicInbound,
 			RunSSH:                 setArgs.runSSH,
 			RunWebClient:           setArgs.runWebClient,
 			Hostname:               setArgs.hostname,
diff --git a/cmd/tailscale/cli/up.go b/cmd/tailscale/cli/up.go
index 79cc60c..1cbea5e 100644
--- a/cmd/tailscale/cli/up.go
+++ b/cmd/tailscale/cli/up.go
@@ -890,6 +890,7 @@ func init() {
 	addPrefFlagMapping("login-server", "ControlURL")
 	addPrefFlagMapping("netfilter-mode", "NetfilterMode")
 	addPrefFlagMapping("shields-up", "ShieldsUp")
+	addPrefFlagMapping("allow-public-inbound", "AllowPublicInbound")
 	addPrefFlagMapping("snat-subnet-routes", "NoSNAT")
 	addPrefFlagMapping("stateful-filtering", "NoStatefulFiltering")
 	addPrefFlagMapping("exit-node-allow-lan-access", "ExitNodeAllowLANAccess")
diff --git a/ipn/ipn_clone.go b/ipn/ipn_clone.go
index 94aebef..c9814eb 100644
--- a/ipn/ipn_clone.go
+++ b/ipn/ipn_clone.go
@@ -84,6 +84,7 @@ func (src *Prefs) Clone() *Prefs {
 	WantRunning                bool
 	LoggedOut                  bool
 	ShieldsUp                  bool
+	AllowPublicInbound         bool
 	AdvertiseTags              []string
 	Hostname                   string
 	NotepadURLs                bool
diff --git a/ipn/ipn_view.go b/ipn/ipn_view.go
index 90560ce..2dfc6dd 100644
--- a/ipn/ipn_view.go
+++ b/ipn/ipn_view.go
@@ -315,6 +315,12 @@ func (v PrefsView) LoggedOut() bool { return v.ж.LoggedOut }
 // connections. This overrides tailcfg.Hostinfo's ShieldsUp.
 func (v PrefsView) ShieldsUp() bool { return v.ж.ShieldsUp }
 
+// AllowPublicInbound bypasses the inbound ACL packet filter for packets
+// received from WireGuard peers. This is a patched-build setting for
+// personal routed-prefix deployments where public clients need to reach
+// this node while preserving their original source IP.
+func (v PrefsView) AllowPublicInbound() bool { return v.ж.AllowPublicInbound }
+
 // AdvertiseTags specifies tags that should be applied to this node, for
 // purposes of ACL enforcement. These can be referenced from the ACL policy
 // document. Note that advertising a tag on the client doesn't guarantee
@@ -486,6 +492,7 @@ func (v PrefsView) Persist() persist.PersistView { return v.ж.Persist.View() }
 	WantRunning                bool
 	LoggedOut                  bool
 	ShieldsUp                  bool
+	AllowPublicInbound         bool
 	AdvertiseTags              []string
 	Hostname                   string
 	NotepadURLs                bool
diff --git a/ipn/ipnlocal/local.go b/ipn/ipnlocal/local.go
index ec16f6a..663b831 100644
--- a/ipn/ipnlocal/local.go
+++ b/ipn/ipnlocal/local.go
@@ -2737,6 +2737,7 @@ type filterInputs struct {
 	LocalNets   views.Slice[netipx.IPRange]
 	LogNets     views.Slice[netipx.IPRange]
 	ShieldsUp   bool
+	PublicIn    bool
 	SSHPolicy   tailcfg.SSHPolicyView
 }
 
@@ -2783,6 +2784,7 @@ func (b *LocalBackend) updateFilterLocked(prefs ipn.PrefsView) {
 		localNetsB   netipx.IPSetBuilder
 		logNetsB     netipx.IPSetBuilder
 		shieldsUp    = !prefs.Valid() || prefs.ShieldsUp() // Be conservative when not ready
+		publicIn     = prefs.Valid() && prefs.AllowPublicInbound() && !shieldsUp
 	)
 	// Log traffic for Tailscale IPs.
 	logNetsB.AddPrefix(tsaddr.CGNATRange())
@@ -2863,6 +2865,7 @@ func (b *LocalBackend) updateFilterLocked(prefs ipn.PrefsView) {
 		LocalNets:   views.SliceOf(localNets.Ranges()),
 		LogNets:     views.SliceOf(logNets.Ranges()),
 		ShieldsUp:   shieldsUp,
+		PublicIn:    publicIn,
 		SSHPolicy:   sshPol,
 	})
 	if !changed {
@@ -2884,6 +2887,7 @@ func (b *LocalBackend) updateFilterLocked(prefs ipn.PrefsView) {
 	} else {
 		b.logf("[v1] netmap packet filter: %v filters", len(packetFilter))
 		filt := filter.New(packetFilter, b.srcIPHasCapForFilter, localNets, logNets, oldFilter, b.logf)
+		filt.SetAllowPublicInbound(publicIn)
 
 		filt.IngressAllowHooks = b.extHost.Hooks().Filter.IngressAllowHooks
 		filt.LinkLocalAllowHooks = b.extHost.Hooks().Filter.LinkLocalAllowHooks
diff --git a/ipn/prefs.go b/ipn/prefs.go
index 72e0cf8..c6f22ea 100644
--- a/ipn/prefs.go
+++ b/ipn/prefs.go
@@ -161,6 +161,12 @@ type Prefs struct {
 	// connections. This overrides tailcfg.Hostinfo's ShieldsUp.
 	ShieldsUp bool
 
+	// AllowPublicInbound bypasses the inbound ACL packet filter for packets
+	// received from WireGuard peers. This is a patched-build setting for
+	// personal routed-prefix deployments where public clients need to reach
+	// this node while preserving their original source IP.
+	AllowPublicInbound bool
+
 	// AdvertiseTags specifies tags that should be applied to this node, for
 	// purposes of ACL enforcement. These can be referenced from the ACL policy
 	// document. Note that advertising a tag on the client doesn't guarantee
@@ -366,6 +372,7 @@ type MaskedPrefs struct {
 	WantRunningSet                bool                `json:",omitempty"`
 	LoggedOutSet                  bool                `json:",omitempty"`
 	ShieldsUpSet                  bool                `json:",omitempty"`
+	AllowPublicInboundSet         bool                `json:",omitempty"`
 	AdvertiseTagsSet              bool                `json:",omitempty"`
 	HostnameSet                   bool                `json:",omitempty"`
 	NotepadURLsSet                bool                `json:",omitempty"`
@@ -570,6 +577,9 @@ func (p *Prefs) pretty(goos string) string {
 	if p.ShieldsUp {
 		sb.WriteString("shields=true ")
 	}
+	if p.AllowPublicInbound {
+		sb.WriteString("allowPublicInbound=true ")
+	}
 	if buildfeatures.HasUseExitNode {
 		if p.ExitNodeIP.IsValid() {
 			fmt.Fprintf(&sb, "exit=%v lan=%t ", p.ExitNodeIP, p.ExitNodeAllowLANAccess)
@@ -676,6 +686,7 @@ func (p *Prefs) Equals(p2 *Prefs) bool {
 		p.LoggedOut == p2.LoggedOut &&
 		p.NotepadURLs == p2.NotepadURLs &&
 		p.ShieldsUp == p2.ShieldsUp &&
+		p.AllowPublicInbound == p2.AllowPublicInbound &&
 		p.NoSNAT == p2.NoSNAT &&
 		p.NoStatefulFiltering == p2.NoStatefulFiltering &&
 		p.NetfilterMode == p2.NetfilterMode &&
diff --git a/ipn/prefs_test.go b/ipn/prefs_test.go
index 347a91e..a9699ef 100644
--- a/ipn/prefs_test.go
+++ b/ipn/prefs_test.go
@@ -50,6 +50,7 @@ func TestPrefsEqual(t *testing.T) {
 		"WantRunning",
 		"LoggedOut",
 		"ShieldsUp",
+		"AllowPublicInbound",
 		"AdvertiseTags",
 		"Hostname",
 		"NotepadURLs",
@@ -251,6 +252,16 @@ func TestPrefsEqual(t *testing.T) {
 			&Prefs{ShieldsUp: true},
 			true,
 		},
+		{
+			&Prefs{AllowPublicInbound: true},
+			&Prefs{AllowPublicInbound: false},
+			false,
+		},
+		{
+			&Prefs{AllowPublicInbound: true},
+			&Prefs{AllowPublicInbound: true},
+			true,
+		},
 
 		{
 			&Prefs{AdvertiseRoutes: nil},
diff --git a/net/tstun/wrap.go b/net/tstun/wrap.go
index 2f5d8c1..c8aad1e 100644
--- a/net/tstun/wrap.go
+++ b/net/tstun/wrap.go
@@ -1198,7 +1198,8 @@ func (t *Wrapper) filterPacketInboundFromWireGuard(p *packet.Parsed, captHook pa
 	}
 
 	var filt *filter.Filter
-	if pc.inboundPacketIsJailed(p) {
+	jailed := pc.inboundPacketIsJailed(p)
+	if jailed {
 		filt = t.jailedFilter.Load()
 	} else {
 		filt = t.filter.Load()
@@ -1207,6 +1208,9 @@ func (t *Wrapper) filterPacketInboundFromWireGuard(p *packet.Parsed, captHook pa
 		return filter.Drop, gro
 	}
 	outcome := filt.RunIn(p, t.filterFlags)
+	if !jailed && outcome != filter.Accept && filt.AllowPublicInbound() {
+		outcome = filter.Accept
+	}
 
 	// Let peerapi through the filter; its ACLs are handled at L7,
 	// not at the packet level.
diff --git a/wgengine/filter/filter.go b/wgengine/filter/filter.go
index b2be836..233dd50 100644
--- a/wgengine/filter/filter.go
+++ b/wgengine/filter/filter.go
@@ -68,6 +68,8 @@ type Filter struct {
 
 	shieldsUp bool
 
+	allowPublicInbound bool
+
 	// IngressAllowHooks are hooks that allow extensions to accept inbound
 	// packets beyond the standard filter rules. Packets that are not dropped
 	// by the direction-agnostic pre-check, but would be not accepted by the
@@ -438,6 +440,19 @@ func (f *Filter) CapsWithValues(srcIP, dstIP netip.Addr) tailcfg.PeerCapMap {
 // incoming) filter.
 func (f *Filter) ShieldsUp() bool { return f.shieldsUp }
 
+// SetAllowPublicInbound configures whether tstun should bypass inbound ACL
+// verdicts for this filter. This is only used by patched builds for personal
+// routed-prefix deployments.
+func (f *Filter) SetAllowPublicInbound(v bool) {
+	f.allowPublicInbound = v
+}
+
+// AllowPublicInbound reports whether tstun should bypass inbound ACL verdicts
+// for this filter.
+func (f *Filter) AllowPublicInbound() bool {
+	return f.allowPublicInbound
+}
+
 // RunIn determines whether this node is allowed to receive q from a
 // Tailscale peer.
 func (f *Filter) RunIn(q *packet.Parsed, rf RunFlags) Response {
