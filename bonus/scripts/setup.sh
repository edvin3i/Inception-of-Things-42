#!/bin/bash

echo -e "=== Prune all previous runs ==="
pkill -f "port-forward.*argocd"
k3d cluster delete serious-cluster
echo -e "== PRUNE COMPLETE ==="


if ! k3d --version &>/dev/null ; then
    echo "k3d is not installed!"
    exit 1
else
    k3d cluster create 'serious-cluster' -p "8888:8888@loadbalancer" -p "8080:8080@loadbalancer" -p "443:443@loadbalancer"
fi

if ! kubectl version --client &>/dev/null ; then
    echo "kubectl is not installed!"
    exit 1
fi

if ! helm version &>/dev/null ; then
    echo "Helm is not installed!"
    exit 1
else
    helm repo add gitlab https://charts.gitlab.io/
    helm repo update
    helm upgrade --install gitlab gitlab/gitlab \
      --namespace gitlab --create-namespace \
      --timeout 600s \
      -f confs/gitlab-values.yaml


    kubectl wait --for=condition=available deployment/gitlab-webservice-default \
      --namespace gitlab --timeout=600s

    kubectl get secret --namespace gitlab gitlab-gitlab-initial-root-password \
      -ojsonpath='{.data.password}' | base64 --decode ; echo

    # Get toolbox pod's name
    TOOLBOX_POD=$(kubectl get pods -n gitlab -l app=toolbox -o jsonpath='{.items[0].metadata.name}')

    # Run Ruby in toolbox pod to get token for the API
    GITLAB_TOKEN=$(kubectl exec -n gitlab "$TOOLBOX_POD" -- \
        gitlab-rails runner "
          user = User.find_by_username('root');
          token = user.personal_access_tokens.create!(
            name: 'argocd-token',
            scopes: ['api', 'read_repository', 'write_repository'],
            expires_at: 365.days.from_now
          );
          puts token.token
        ")

    echo "=== Gitlab Token: $GITLAB_TOKEN ==="


    GITLAB_URL="http://gitlab-webservice-default.gitlab.svc:8181"
    PROJECT_NAME="iot-gbreana-demo-app"

    # Create the project in GitLab
    curl --request POST \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --header "Content-Type: application/json" \
        --data "{\"name\": \"$PROJECT_NAME\", \"visibility\": \"public\", \"initialize_with_readme\": true}" \
        "$GITLAB_URL/api/v4/projects"

    sleep 5

    APP_CONTENT=$(base64 -w 0 < confs/my_app.yaml)

    curl --request POST \
        --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        --header "Content-Type: application/json" \
        --data "{\"branch\": \"main\", \"commit_message\": \"add app manifest\", \"encoding\": \"base64\", \"content\": \"$APP_CONTENT\"}" \
        "$GITLAB_URL/api/v4/projects/root%2F$PROJECT_NAME/repository/files/manifests%2Fmy_app.yaml"


    # Deploy ArgoCD
    kubectl create namespace argocd
    kubectl apply --namespace argocd --server-side --force-conflicts \
            -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

    echo -e "\n=== Initial ArgoCD password ===:"
    kubectl --namespace argocd get secret argocd-initial-admin-secret \
            -o jsonpath="{.data.password}" | base64 -d \
            && echo -e "\n=== END ===:"

    kubectl port-forward svc/argocd-server --namespace argocd 8080:443&

    # Create the ArgoCD secret
    kubectl create secret generic gitlab-repo \
        --namespace argocd \
        --from-literal=type=git \
        --from-literal=url="$GITLAB_URL/root/$PROJECT_NAME.git" \
        --from-literal=username=root \
        --from-literal=password="$GITLAB_TOKEN" \
        --from-literal=insecure="true"

    kubectl label secret gitlab-repo \
        --namespace argocd \
        argocd.argoproj.io/secret-type=repository





    kubectl create namespace dev
    kubectl apply -f confs/argocd_app.yaml

fi
