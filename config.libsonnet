{
  _config+:: {
    helm:: {
      Capabilities:: {
        KubeVersion: 'v1.24.0',
      },
    },

    linkerd2_cni+: {
      local c = self,
      kubeVersion: $._config.helm.Capabilities.KubeVersion,
      namespace: 'linkerd-cni', // This may need special care if customizing together with enablePSP: true
      enablePSP: false,
      iKnowWhatImDoing: false,

      assert !self.enablePSP || self.namespace == 'linkerd-cni' || self.iKnowWhatImDoing : |||
        Using a custom namespace is not supported together with enablePSP.
        If PSP + a custom namespace is desired, set the `iKnowWhatImDoing` value to true
        while also adding this to your environment: + {
          pod_security_policy_linkerd_custom_namespace_cni+:
            k.policy.v1beta1.podSecurityPolicy.spec.withVolumesMixin(['configMap']),
          }
      |||,

      // In newer versions, this is now default to empty again and instead have added
      // proxyAdminPort and proxyControlPort values that allow proxy inbound traffic.
      ignoreInboundPorts: [],
      ignoreOutboundPorts: [],

      values+: {
        local values = self,
        enablePSP: c.enablePSP,
        ignoreInboundPorts: std.join(',', c.ignoreInboundPorts),
        ignoreOutboundPorts: std.join(',', c.ignoreOutboundPorts),
      },
    },
  },
}
