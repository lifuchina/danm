FROM alpine:3.7
MAINTAINER Levente Kale <levente.kale@nokia.com>

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

COPY build.sh /build.sh

RUN apk add --no-cache ca-certificates \
 && apk update --no-cache \
 && apk upgrade --no-cache \
 && apk add --no-cache make gcc musl-dev go glide git bash bash-completion \
 && mkdir -p $GOPATH/bin \
 && mkdir -p $GOPATH/src/github.com/nokia/danm \
 && rm -rf /var/cache/apk/* \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/*

COPY pkg /go/src/github.com/nokia/danm/pkg

ENV CGO_ENABLED 0
ENV GOOS linux
RUN cd /go/src/github.com/nokia/danm/pkg \
 && glide install \
 && go get -d github.com/vishvananda/netlink \
 && go get github.com/golang/groupcache/lru \
 && go get k8s.io/code-generator/cmd/deepcopy-gen \
 && go get k8s.io/code-generator/cmd/client-gen \
 && go get k8s.io/code-generator/cmd/lister-gen \
 && go get k8s.io/code-generator/cmd/informer-gen \
 && deepcopy-gen -v5 --alsologtostderr --input-dirs github.com/nokia/danm/pkg/crd/apis/danm/v1 -O zz_generated.deepcopy --bounding-dirs github.com/nokia/danm/pkg/crd/apis \
 && client-gen -v5 --alsologtostderr --clientset-name versioned --input-base "" --input github.com/nokia/danm/pkg/crd/apis/danm/v1 --clientset-path github.com/nokia/danm/pkg/crd/client/clientset \
 && lister-gen -v5 --alsologtostderr --input-dirs github.com/nokia/danm/pkg/crd/apis/danm/v1 --output-package github.com/nokia/danm/pkg/crd/client/listers \
 && informer-gen -v5 --alsologtostderr --input-dirs github.com/nokia/danm/pkg/crd/apis/danm/v1 --versioned-clientset-package github.com/nokia/danm/pkg/crd/client/clientset/versioned --listers-package github.com/nokia/danm/pkg/crd/client/listers --output-package github.com/nokia/danm/pkg/crd/client/informers \ 
 && go install -a -ldflags '-extldflags "-static"' github.com/nokia/danm/pkg/danm
 && go install -a -ldflags '-extldflags "-static"' github.com/nokia/danm/pkg/netwatcher
 && go install -a -ldflags '-extldflags "-static"' github.com/nokia/danm/pkg/fakeipam
 && go install -a -ldflags '-extldflags "-static"' github.com/nokia/danm/pkg/svcwatcher
