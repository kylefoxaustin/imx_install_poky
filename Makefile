.PHONY: build run

REPO  ?= kylefoxaustin/imx_install_poky
TAG   ?= latest

build:
	docker build -t $(REPO):$(TAG) --build-arg localbuild=1 .

run:
	docker run \
		-i \
		-v ~/media/kyle/1tb/linuxdata/imx8development/junkdock/imxpoky:/root/nxp/ \
--name imx_install_poky_test \
		$(REPO):$(TAG)

shell:
	docker exec -it imx_install_poky_test bash

