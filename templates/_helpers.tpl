{{/*
Expand the name of the chart.
*/}}
{{- define "chainweb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chainweb.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chainweb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chainweb.labels" -}}
helm.sh/chart: {{ include "chainweb.chart" . }}
{{ include "chainweb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chainweb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chainweb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chainweb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chainweb.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* ************************************************************************* */}}
{{/* TLS */}}

{{/*
Default nginx ingress SSL annotations
*/}}
{{- define "chainweb.ingress.sslAnnotations" }}
{{- if .Values.tls.enabled }}
nginx.ingress.kubernetes.io/ssl-redirect: "true"
nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
cert-manager.io/issuer: {{ include "chainweb.tls.issuerName" . }}
{{- end }}
{{- end }}

{{/*
TLS issuer name
*/}}
{{- define "chainweb.tls.issuerName" }}
{{- include "chainweb.fullname" . }}-tls-{{ or (and .Values.tls.staging "staging") "prod" }}
{{- end }}

{{/*
TLS secret name
*/}}
{{- define "chainweb.tls.secretName" }}
{{- include "chainweb.fullname" . }}-tls-{{ or (and .Values.tls.staging "staging") "prod" }}
{{- end }}
