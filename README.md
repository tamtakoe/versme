# version-management
Lightweight alpine-based docker image of version bumping for CI-CD

### Publish
```
docker build -t tamtakoe/version-management:latest .
docker login
docker push tamtakoe/version-management:latest
```