{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "secrets-safe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "secrets-safe.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "secrets-safe.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "secrets-safe.labels" -}}
app.kubernetes.io/name: {{ include "secrets-safe.name" . }}
helm.sh/chart: {{ include "secrets-safe.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Define a success value only when we use a hostname other than 'any' when we supply a certificate
*/}}
{{- define "validCertificateHost" -}}
{{- if or (ne .Values.ingress.host "any") (eq .Values.ingress.certificateSecretName "") -}}
{{ .Values.ingress.host }}
{{- end -}}
{{- end -}}

{{/*
Define the replicas based on whether there is an override or based on performance-optimizing defaults
*/}}
{{- define "auditor.replicas" -}}
{{- if .Values.numberOfReplicas -}}
{{ .Values.numberOfReplicas }}
{{- else -}}
2
{{- end -}}
{{- end -}}
{{- define "authenticator.replicas" -}}
{{- if .Values.numberOfReplicas -}}
{{ .Values.numberOfReplicas }}
{{- else -}}
2
{{- end -}}
{{- end -}}
{{- define "authorizer.replicas" -}}
{{- if .Values.numberOfReplicas -}}
{{ .Values.numberOfReplicas }}
{{- else -}}
3
{{- end -}}
{{- end -}}
{{- define "healthmonitor.replicas" -}}
{{- if .Values.numberOfReplicas -}}
{{ .Values.numberOfReplicas }}
{{- else -}}
2
{{- end -}}
{{- end -}}
{{- define "keymanager.replicas" -}}
{{- if .Values.numberOfReplicas -}}
{{ .Values.numberOfReplicas }}
{{- else -}}
2
{{- end -}}
{{- end -}}
{{- define "lockbox.replicas" -}}
{{- if .Values.numberOfReplicas -}}
{{ .Values.numberOfReplicas }}
{{- else -}}
3
{{- end -}}
{{- end -}}
{{- define "standardgateway.replicas" -}}
{{- if .Values.numberOfReplicas -}}
{{ .Values.numberOfReplicas }}
{{- else -}}
3
{{- end -}}
{{- end -}}
{{- define "rabbitmq.replicas" -}}
{{- if .Values.numberOfReplicas -}}
{{ .Values.numberOfReplicas }}
{{- else -}}
3
{{- end -}}
{{- end -}}

{{/*
Define the images based on whether there is an override or whether it uses the global tag
*/}}
{{- define "auditor.image" -}}
{{- if .Values.auditorImageTagOverride -}}
{{ .Values.registryName }}/auditor:{{ .Values.auditorImageTagOverride }}
{{- else -}}
{{ .Values.registryName }}/auditor:{{ .Values.imageTag }}
{{- end -}}
{{- end -}}

{{- define "authorizer.image" -}}
{{- if .Values.authorizerImageTagOverride -}}
{{ .Values.registryName }}/authorizer:{{ .Values.authorizerImageTagOverride }}
{{- else -}}
{{ .Values.registryName }}/authorizer:{{ .Values.imageTag }}
{{- end -}}
{{- end -}}

{{- define "healthmonitor.image" -}}
{{- if .Values.healthmonitorImageTagOverride -}}
{{ .Values.registryName }}/healthmonitor:{{ .Values.healthmonitorImageTagOverride }}
{{- else -}}
{{ .Values.registryName }}/healthmonitor:{{ .Values.imageTag }}
{{- end -}}
{{- end -}}

{{- define "keymanager.image" -}}
{{- if .Values.keymanagerImageTagOverride -}}
{{ .Values.registryName }}/keymanager:{{ .Values.keymanagerImageTagOverride }}
{{- else -}}
{{ .Values.registryName }}/keymanager:{{ .Values.imageTag }}
{{- end -}}
{{- end -}}

{{- define "authenticator.image" -}}
{{- if .Values.authenticatorImageTagOverride -}}
{{ .Values.registryName }}/authenticator:{{ .Values.authenticatorImageTagOverride }}
{{- else -}}
{{ .Values.registryName }}/authenticator:{{ .Values.imageTag }}
{{- end -}}
{{- end -}}

{{- define "lockbox.image" -}}
{{- if .Values.lockboxImageTagOverride -}}
{{ .Values.registryName }}/lockbox:{{ .Values.lockboxImageTagOverride }}
{{- else -}}
{{ .Values.registryName }}/lockbox:{{ .Values.imageTag }}
{{- end -}}
{{- end -}}

{{- define "standardgateway.image" -}}
{{- if .Values.standardgatewayImageTagOverride -}}
{{ .Values.registryName }}/standardgateway:{{ .Values.standardgatewayImageTagOverride }}
{{- else -}}
{{ .Values.registryName }}/standardgateway:{{ .Values.imageTag }}
{{- end -}}
{{- end -}}

