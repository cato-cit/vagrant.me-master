WORKSPACE='workspace'

.PHONY: clean
clean:
	@cd $(WORKSPACE); \
	    rm -rf puppet/ Vagrantfile Dockerfile README.md

.PHONY: build
build: check-arg
	@mkdir -p $(WORKSPACE);
	@cp -r _skeleton/* $(WORKSPACE)/;
	@cd $(WORKSPACE); \
	    mkdir -p docroot; \
	    find puppet/ Vagrantfile Dockerfile README.md -type f | xargs sed -i "s/@@PROJECT@@/$(PROJECT)/g"; \
		mv puppet/modules/apache/files/vhosts/sample.conf puppet/modules/apache/files/vhosts/$(PROJECT).conf; \
		mv puppet/modules/apache/files/vhosts/sample-ssl.conf puppet/modules/apache/files/vhosts/$(PROJECT)-ssl.conf;
.PHONY: check-arg
check-arg:
ifndef PROJECT
	$(error PROJECT is undefined)
endif
