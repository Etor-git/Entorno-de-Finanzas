# backend/app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime

app = Flask(__name__)
CORS(app)

def get_conn():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="123456789",   # cambia
        database="gastos_app"
    )

# --- Crear gasto (POST) ---
@app.route("/api/gastos", methods=["POST"])
def crear_gasto():
    data = request.json
    concepto = data.get("concepto")
    cantidad = data.get("cantidad")

    if concepto is None or cantidad is None:
        return jsonify({"error": "Faltan campos"}), 400

    fecha = datetime.now().strftime("%Y-%m-%d")
    hora = datetime.now().strftime("%H:%M:%S")

    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO gastos (fecha, hora, concepto, cantidad) VALUES (%s, %s, %s, %s)",
        (fecha, hora, concepto, float(cantidad))
    )
    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"status": "ok"}), 201

# --- Gastos de un día (GET) ---
@app.route("/api/gastos/dia", methods=["GET"])
def gastos_dia():
    fecha = request.args.get("fecha")  # formato YYYY-MM-DD; si no, usar hoy
    if not fecha:
        fecha = datetime.now().strftime("%Y-%m-%d")

    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT hora, concepto, cantidad FROM gastos WHERE fecha = %s ORDER BY hora ASC", (fecha,))
    rows = cursor.fetchall()
    cursor.close()
    conn.close()

    resultados = [{"hora": r[0].strftime("%H:%M:%S") if hasattr(r[0],"strftime") else str(r[0]), "concepto": r[1], "cantidad": float(r[2])} for r in rows]
    total = sum(r["cantidad"] for r in resultados)
    return jsonify({"fecha": fecha, "total": total, "gastos": resultados})

# --- Totales últimos 7 días (GET) ---
@app.route("/api/gastos/semana", methods=["GET"])
def gastos_semana():
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT fecha, SUM(cantidad) as total
        FROM gastos
        GROUP BY fecha
        ORDER BY fecha DESC
        LIMIT 7
    """)
    rows = cursor.fetchall()
    cursor.close()
    conn.close()

    # Orden cronológico ascendente para graficar correctamente
    rows = list(rows)[::-1]
    data = [{"fecha": str(r[0]), "total": float(r[1])} for r in rows]
    return jsonify({"dias": data})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050, debug=True)