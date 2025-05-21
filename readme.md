# trilium

```
kubectl apply -f trilium-pv.yaml
kubectl apply -f trilium-pvc.yaml
helm install trilium-test trilium/trilium -f helm/trilium-default-values.yaml

# Ingress 시 생략 ㄱㄴ
kubectl port-forward service/trilium-test 8080:8080
```

# Ingress 세팅

minikube ip 192.168.64.54 trilium.local

#
