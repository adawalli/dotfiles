function kp -d "Kube populate - login to all Teleport Kubernetes clusters"
    tsh kube ls | tail +3 | gawk '{print $1}' | xargs -n1 tsh kube login --set-context-name="{{.KubeName}}"
end
