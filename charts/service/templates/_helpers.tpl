{{/* Define a chart-wide name template */}}
{{- define "app.name" -}}
{{ .Values.name | default .Chart.Name }}
{{- end }}

{{/* Define standard labels */}}
{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
