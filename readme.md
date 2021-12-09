# one to many routing in pgRouting

**Vorbedingung**

### Python fit machen
```
    # Code auschecken, virtual env aufsetzen, benötigte Python-Module installieren
    python3 -m venv routing_env
    python3 -m pip install --upgrade pip
    source venv/bin/activate
    pip install -r requirements.txt
```

**Config anpassen**

```
 vim .flaskenv 
```

**DB vorbereiten**

    1. psql -c 'create database skeleton;'
    2. psql: create schema gizmo
    3. flask db upgrade
    4. flask seed run BookSeeder


**User anlegen**

flask my_app create_user --username='annalena' --password='ChristianLindnerWirdNichtZumGeburtstagEingeladen'

**Starten**
```
..
```