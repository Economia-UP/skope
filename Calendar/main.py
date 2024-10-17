import json
import xml.etree.ElementTree as ET
import requests
from datetime import datetime, timedelta
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build
import os

# Configuración: URL del RSS y ID del calendario
RSS_URL = "https://www.inegi.org.mx/rss/noticias/xmlfeeds?p="
CALENDAR_ID = os.getenv("GOOGLE_CALENDAR_ID")

# Autenticación usando Google Calendar API
def autenticar_google_calendar():
    credentials_json = os.getenv("GOOGLE_CREDENTIALS_JSON")
    creds = Credentials.from_service_account_info(
        json.loads(credentials_json), 
        scopes=["https://www.googleapis.com/auth/calendar"]
    )
    return build("calendar", "v3", credentials=creds)

# Leer el RSS y extraer los eventos
def leer_rss():
    response = requests.get(RSS_URL)
    root = ET.fromstring(response.content)
    eventos = []

    for row in root.findall("./channel/row"):
        titulo = row.find("title").text
        descripcion = row.find("description").text
        fecha_pub = datetime.strptime(row.find("pubdate").text, "%a, %d %b %Y %H:%M:%S %Z")

        eventos.append({
            "summary": titulo,
            "description": descripcion,
            "start": fecha_pub.isoformat(),
            "end": (fecha_pub + timedelta(hours=1)).isoformat()
        })
    return eventos

# Crear eventos en Google Calendar
def crear_eventos(service, eventos):
    for evento in eventos:
        evento_body = {
            "summary": evento["summary"],
            "description": evento["description"],
            "start": {"dateTime": evento["start"], "timeZone": "America/Mexico_City"},
            "end": {"dateTime": evento["end"], "timeZone": "America/Mexico_City"},
        }
        service.events().insert(calendarId=CALENDAR_ID, body=evento_body).execute()

if __name__ == "__main__":
    service = autenticar_google_calendar()
    eventos = leer_rss()
    crear_eventos(service, eventos)
