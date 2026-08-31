{{- /*
  Values checks that `values.schema.json` cannot express, either because they
  span more than one key or because they depend on the length of a list.
  Included once from mongodb-deployment.yaml so that a bad values file fails at
  render time rather than at reconcile time.
*/ -}}
{{- define "mongodb-deployment.validate" -}}

{{- $sharded := and (hasKey .Values "sharding") (eq ((.Values.sharding | default dict).enabled | default false) true) -}}
{{- $replicaSet := and (hasKey .Values "replicaSet") (eq ((.Values.replicaSet | default dict).enabled | default false) true) -}}
{{- if and $sharded $replicaSet }}
{{- fail "only one of sharding.enabled and replicaSet.enabled can be true" }}
{{- end }}
{{- if not (or $sharded $replicaSet) }}
{{- fail "one of sharding.enabled or replicaSet.enabled must be true" }}
{{- end }}

{{- if hasKey .Values "mongoDBFCV" }}
{{- if not (and (kindIs "string" .Values.mongoDBFCV) (regexMatch "^\\d+\\.\\d+$" .Values.mongoDBFCV)) }}
{{- fail "mongoDBFCV must be a string in the format of \"x.x\", such as \"6.0\"" }}
{{- end }}
{{- end }}

{{- $mode := ((.Values.externalAccess | default dict).mode | default "operator") -}}
{{- if not (has $mode (list "operator" "chart")) }}
{{- fail "externalAccess.mode must be either \"operator\" or \"chart\"" }}
{{- end }}

{{- if not (regexMatch "^https?://" (.Values.opsManager.baseUrl | default "")) }}
{{- fail "opsManager.baseUrl must be a URL starting with http:// or https://" }}
{{- end }}

{{- $scram := and (hasKey .Values.auth "scram") (eq (.Values.auth.scram.enabled | default false) true) -}}
{{- $ldap := and (hasKey .Values.auth "ldap") (eq (.Values.auth.ldap.enabled | default false) true) -}}
{{- if not (or $scram $ldap) }}
{{- fail "at least one of auth.scram.enabled or auth.ldap.enabled must be true" }}
{{- end }}
{{- if $ldap }}
{{- range $key := list "servers" "bindUserDN" "bindUserSecret" }}
{{- if not (get $.Values.auth.ldap $key) }}
{{- fail (printf "auth.ldap.%s is required when auth.ldap.enabled is true" $key) }}
{{- end }}
{{- end }}
{{- if and (eq (.Values.auth.ldap.ldaps | default false) true) (not .Values.auth.ldap.caConfigMap) }}
{{- fail "auth.ldap.caConfigMap is required when auth.ldap.ldaps is true" }}
{{- end }}
{{- end }}

{{- if $replicaSet }}
{{- $ext := (.Values.replicaSet.extAccess | default dict) -}}
{{- if and (eq ($ext.enabled | default false) true) $ext.ports }}
{{- if ne (len $ext.ports) (int .Values.replicaSet.replicas) }}
{{- fail (printf "replicaSet.extAccess.ports has %d entries but replicaSet.replicas is %d; the operator requires one replica set horizon per member" (len $ext.ports) (int .Values.replicaSet.replicas)) }}
{{- end }}
{{- if ne (.Values.tls.enabled | default false) true }}
{{- fail "tls.enabled must be true to use replicaSet.extAccess; the operator requires TLS (SNI) for replica set horizons" }}
{{- end }}
{{- end }}
{{- end }}

{{- if hasKey .Values "backup" }}
{{- if not (has (.Values.backup.mode | default "" | lower) (list "enabled" "disabled" "terminated")) }}
{{- fail "backup.mode must be one of \"enabled\", \"disabled\" or \"terminated\"" }}
{{- end }}
{{- end }}

{{- end -}}
