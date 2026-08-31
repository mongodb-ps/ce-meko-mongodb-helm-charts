{{- define "mongodb-deployment.name" -}}
{{- default .Chart.Name .Values.deploymentName -}}
{{- end -}}

{{- /* Agent startup options, shared by shard, mongos, configSrv and replica set */ -}}
{{- define "mongodb-deployment.agentStartupOptions" -}}
logLevel: {{ .Values.agent.logLevel | default "INFO" }}
{{- if .Values.agent.startupOptions }}
{{- range $key, $value := .Values.agent.startupOptions }}
{{ $key }}: {{ ($value | toString) | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{- /* additionalMongodConfig, shared by shard, mongos, configSrv and replica set */ -}}
{{- define "mongodb-deployment.additionalMongodConfig" -}}
{{- if .Values.tls.enabled }}
net:
  tls:
    mode: requireTLS
    disabledProtocols: TLS1_0,TLS1_1
setParameter:
  suppressNoTLSPeerCertificateWarning: true
{{- end }}
systemLog:
  verbosity: {{ if eq (.Values.logLevel | default "INFO" | upper) "DEBUG" }}2{{ else }}0{{ end }}
  timeStampFormat: iso8601-local
{{- end -}}

{{- /*
  MCK 1.11.0 removed `spec.exposedExternally` (dropped in MEKO 1.23), replacing it
  with `spec.externalAccess`. Takes a dict of `root` (the top level context) and
  `extAccess` (either `replicaSet.extAccess` or `sharding.extAccess`).
  The `externalService` stanza is only emitted when the operator owns the Services,
  i.e. `externalAccess.mode` is `operator`; under `chart` mode the Services come
  from mongodb-svc.yaml instead.
*/ -}}
{{- define "mongodb-deployment.externalAccess" -}}
{{- $ea := .root.Values.externalAccess | default dict -}}
{{- $ext := .extAccess | default dict -}}
{{- if $ea.externalDomain }}
externalDomain: {{ $ea.externalDomain | quote }}
{{- end }}
{{- if eq ($ea.mode | default "operator") "operator" }}
externalService:
  {{- with $ea.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  spec:
    type: {{ ternary "NodePort" "LoadBalancer" (eq ($ext.exposeMethod | default "NodePort" | lower) "nodeport") }}
{{- end }}
{{- end -}}

{{- /*
  Extra SAN domains for the member certificates. Sourced from `tls.additionalCertificateDomains`
  or, for backwards compatibility, from the `extAccess.externalDomains` of whichever deployment
  type is enabled. Emitted as a YAML array.
*/ -}}
{{- define "mongodb-deployment.additionalCertificateDomains" -}}
{{- $domains := .Values.tls.additionalCertificateDomains | default list -}}
{{- range (list (.Values.sharding | default dict) (.Values.replicaSet | default dict)) }}
{{- $domains = concat $domains ((.extAccess | default dict).externalDomains | default list) }}
{{- end }}
{{- if $domains }}
{{- $domains | uniq | toYaml }}
{{- end }}
{{- end -}}
