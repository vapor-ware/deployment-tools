build:
	docker build -t local/deployment-tools:latest .

clean:
	docker rmi local/deployment-tools:latest

public:
	docker build -t vaporio/deployment-tools:$(shell contrib/semtag getcurrent) .

