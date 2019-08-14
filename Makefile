build:
	docker build -t vaporio/deployment-tools:latest .

clean:
	docker rmi vaporio/deployment-tools:latest

public:
	docker build -t vaporio/deployment-tools:$(shell contrib/semtag getcurrent) .

