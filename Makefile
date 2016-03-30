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
	    find puppet/ Vagrantfile Dockerfile README.md -type f | xargs sed -i "s/@@PROJECT@@/$(PROJECT)/g";

.PHONY: check-arg
check-arg:
ifndef PROJECT
	$(error PROJECT is undefined)
endif
