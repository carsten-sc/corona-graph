# corona-graph

## About

A timeline graph system based on graphite and grafana to show corona cases and deaths for countries an global.It will setup on a basic centos8-stream image in a virtual box from scratch.

The underlying data is provided by Johns Hopkins University.

> Published by Dong E, Du H, Gardner L. <https://doi.org/10.1016/S1473-3099(20)30120-1> Lancet Inf Dis. 20(5):533-534. doi: 10.1016/S1473-3099(20)30120-1 Center for Systems Science and Engineering (CSSE) at Johns Hopkins University.

View on github: <https://github.com/CSSEGISandData/COVID-19>

## Installation

you need python3, vagrant and virtualbox on your system

``` bash

git clone https://github.com/carsten-sc/corona-graph.git

cd corona-graph

vagrant plugin install vagrant-vbguest

vagrant up

```

After installing, open localhost:3000 for grafana dashboard. A sample dashboard is installed

user/password: admin/admin
