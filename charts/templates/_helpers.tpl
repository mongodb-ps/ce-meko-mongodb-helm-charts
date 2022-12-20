{{- define "mongodb-deployment.name" -}}
{{- default .Chart.Name .Values.deploymentName -}}
{{- end -}}