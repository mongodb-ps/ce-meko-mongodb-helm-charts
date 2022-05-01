{{- define "mongodb-replicaset.name" -}}
{{- default .Chart.Name .Values.deploymentName -}}
{{- end -}}