# linkerd2-libsonnet

Generates production-ready manifests for:

- linkerd2 (Not OpenSource yet)
- linkerd2-viz (Not OpenSource yet)
- linkerd2-cni (edge-23.4.1 + local `install-cni.sh` [patch](install-cni-moved_to.patch). See: https://github.com/linkerd/linkerd2/issues/10669 )

## Getting started

If you use [Homebrew](https://brew.sh):

```sh
brew install vmware-tanzu/carvel/vendir jsonnet-bundler tanka
tk init --k8s 1.24
jb install github.com/cloud-destroyer/linkerd2-libsonnet

# Add the needed locally vendored chart(s):
cd vendor/linkerd2-libsonnet
make
```

## Using the Jsonnet library in a Tanka environment

Running `tk init` should have created a file in `environments/default/main.jsonnet`. Edit it:

```jsonnet
local linkerd2_cni = import 'linkerd2-libsonnet/linkerd2-cni.libsonnet';

linkerd2_cni {

}
```

### Generate or show the manifests

```sh
# Show the manifests ...
tk show environments/default

# Export them to a manifests/ folder ...
tk export manifests/ environments/default
```

### Apply the manifests to a cluster

The many ways of accomplishing this is way beyond what any mortal can comprehend. But here's an example using `kapp` from Carvel:

```sh
# Need to delete this manifest file because kapp attempts to parse it as well
rm manifests/manifest.json

# kapp deploy
kapp deploy -a linkerd2-cni -f manifests/


# kapp deploy with showing diff
kapp deploy -a linkerd2-cni -f manifests/ --diff-changes

```

## Customizing the deployment

See [config.libsonnet](config.libsonnet) for the specific configuration values `linkerd2-libsonnet` supports.

On top of what this library *directly* supports, you can also customize all the Helm chart values directly in `$._config.linkerd2_cni.values`.

There is special handling needed for changing the `namespace` when `enablePSP` is set to `true`. See example below for using a `custom-namespace`:

```jsonnet
local k = import 'k.libsonnet';
local linkerd2_cni = import 'linkerd2-libsonnet/linkerd2-cni.libsonnet';

linkerd2_cni {
  _config+: {
    linkerd2_cni+: {
      enablePSP: true,
      namespace: 'custom-namespace',
      iKnowWhatImDoing: true,
      values+: {

      },
    },
  },
} + {
  helm_template+: {

    // This manual field override using custom naming of the field name is needed if
    // the namespace is something other than 'linkerd-cni'.
    pod_security_policy_linkerd_custom_namespace_cni+:
      k.policy.v1beta1.podSecurityPolicy.spec.withVolumesMixin(['configMap']),
  },

}

```