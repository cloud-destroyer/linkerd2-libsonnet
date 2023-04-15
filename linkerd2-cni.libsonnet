local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);
local k = import 'k.libsonnet',
      configMap = k.core.v1.configMap,
      daemonSet = k.apps.v1.daemonSet,
      namespace = k.core.v1.namespace;
local util = (import 'github.com/grafana/jsonnet-libs/ksonnet-util/util.libsonnet').withK(k);

(import 'config.libsonnet') +
{
  // For convenience point c to 'our' config namespace 'linkerd2_cni'
  local c = $._config.linkerd2_cni,

  helm_template:
    helm.template('linkerd2-cni', './gitvendor/charts/linkerd2-cni', {
      namespace: c.namespace,
      values: c.values,
      kubeVersion: $._config.helm.Capabilities.KubeVersion,
    }) + {

      namespace_linkerd_cni:
        namespace.new(c.namespace)
        + namespace.metadata.withAnnotations({
          'linkerd.io/inject': 'disabled',
        })
        + namespace.metadata.withLabels({
          'linkerd.io/cni-resource': 'true',
          'config.linkerd.io/admission-webhooks': 'disabled',
        }),

      configmap_linkerd_install_cni:
        configMap.new('linkerd-install-cni')
        + configMap.metadata.withNamespace(c.namespace)
        + configMap.withData({
          'install-cni.sh': (importstr './gitvendor/cni-plugin/deployment/scripts/install-cni.sh'),
        }),

      daemon_set_linkerd_cni+:
        daemonSet.configMapVolumeMount(
          self.configmap_linkerd_install_cni,
          '/linkerd/install-cni.sh',
          volumeMountMixin=k.core.v1.volumeMount.withSubPath('install-cni.sh'),  // Mount our patched version of install-cni.sh: https://github.com/linkerd/linkerd2/issues/2219#issuecomment-1170778317
          volumeMixin=k.core.v1.volume.configMap.withDefaultMode(493),
        )
        + daemonSet.spec.template.spec.withPriorityClassName('system-node-critical'),


    } + if $._config.linkerd2_cni.enablePSP && $._config.linkerd2_cni.namespace == 'linkerd-cni' then {
      pod_security_policy_linkerd_linkerd_cni_cni+:
        k.policy.v1beta1.podSecurityPolicy.spec.withVolumesMixin(['configMap']),
    } else {},

}
