import xml.etree.ElementTree as ET
import requests
from datetime import datetime, timedelta
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build
import os
import json  # Ensure json is imported

# Configuration: RSS URL and Calendar ID
RSS_URL = "https://www.inegi.org.mx/rss/noticias/xmlfeeds?p="
CALENDAR_ID = os.getenv("GOOGLE_CALENDAR_ID")

# Authenticate using Google Calendar API
def autenticar_google_calendar():
    credentials_json = os.getenv("GOOGLE_CREDENTIALS_JSON")
    creds = Credentials.from_service_account_info(
        json.loads(credentials_json), 
        scopes=["https://www.googleapis.com/auth/calendar"]
    )
    return build("calendar", "v3", credentials=creds)

# Read the RSS and extract events
def leer_rss():
    response = requests.get(RSS_URL)
    root = ET.fromstring(response.content)
    eventos = []

    for row in root.findall("./channel/row"):
        titulo = row.find("title").text
        descripcion = row.find("description").text
        pubdate_text = row.find("pubdate").text
        
        # Check the format of pubdate
        try:
            # Attempt to parse with time
            fecha_pub = datetime.strptime(pubdate_text, "%a, %d %b %Y %H:%M:%S %Z")
        except ValueError:
            # If it fails, try parsing without time
            fecha_pub = datetime.strptime(pubdate_text, "%a, %d %b %Y")

        eventos.append({
            "summary": titulo,
            "description": descripcion,
            "start": fecha_pub.isoformat(),
            "end": (fecha_pub + timedelta(hours=1)).isoformat()
        })
    return eventos

# Create events in Google Calendar
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
