README.md: main.libsonnet example.libsonnet
	jrsonnet -S -c -m . \
		--os-stack 1000 \
		--max-stack 1000000 \
		-J vendor \
		example.libsonnet
