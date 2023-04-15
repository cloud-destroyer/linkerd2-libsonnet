all: patch-cni

.PHONY: vendor-cni
vendor-cni:
	vendir sync
	mkdir gitvendor/charts/linkerd2-cni/charts
	mv gitvendor/charts/partials gitvendor/charts/linkerd2-cni/charts/partials

.PHONY: patch-cni
patch-cni: vendor-cni
	patch -p3 <install-cni-moved_to.patch
