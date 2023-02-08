# Переключение между контекстами с kubectl

```bash
➜  ~ kubectl config get-contexts
CURRENT   NAME        CLUSTER     AUTHINFO          NAMESPACE
*         k8s-dev     k8s-dev     k8s-dev-admin
          k8s-local   k8s-local   k8s-local-admin
```

## Чтобы переключиться на другой контекст, используйте:

Переключился на контекст "k8s-local"

```bash
➜  ~ kubectl config use-context k8s-local
```

Переключился на контекст "k8s-dev"

```bash
➜  ~ kubectl config use-context k8s-dev
```

Проверка что контекст k8s-dev

```bash
➜  ~ kubectl get nodes
NAME                                 STATUS   ROLES    AGE    VERSION
dev-cluster-00-master-1              Ready    <none>   215d   v1.22.3
dev-cluster-00-node-1                Ready    <none>   93d    v1.22.3
dev-cluster-00-node-2                Ready    <none>   93d    v1.22.3
```

## Выполнение с другим контекстом
```bash
➜  ~ kubectl --context k8s-local get nodes
NAME             STATUS   ROLES           AGE    VERSION
minikub          Ready    control-plane   110m   v1.25.2
```