RELEASE=1.0.69
clean:
	rm -rf public test data/releases.yml

run: deps
	# CSS gets mashed if we don't use --disableFastRender
	hugo server --disableFastRender

data/releases.yml:
	curl -s https://repo.humio.com/repository/maven-releases/com/humio/server/$(RELEASE)/server-$(RELEASE).releases.yml > data/releases.yml

data/functions.json:
	curl -s https://repo.humio.com/repository/maven-releases/com/humio/docs/queryfunctions/$(RELEASE)/queryfunctions-$(RELEASE).json > data/functions.json

deps: data/releases.yml data/functions.json

public: deps
	hugo
	docker build --tag="humio/docs:latest" .

test: public
	docker rm -f humio-docs || true
	docker run -d --name=humio-docs humio/docs
	mkdir -p test
	docker run --rm --user 1 -v ${PWD}/test:/data --link=humio-docs:humio-docs praqma/linkchecker linkchecker --no-status -ocsv http://humio-docs/ > test/report.csv
	docker rm -f humio-docs
