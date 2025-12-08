from flask import Flask, jsonify
import sqlite3

app = Flask(__name__)
DB_NAME = "sensor_data.db"

def get_db_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/api/latest', methods=['GET'])
def get_latest_reading():
    conn = get_db_connection()
    reading = conn.execute("SELECT * FROM dht_readings ORDER BY id DESC LIMIT 1").fetchone()
    conn.close()
    
    if reading is None:
        return jsonify({"message": "No data available"}), 404
        
    return jsonify(dict(reading))

@app.route('/api/history/<int:count>', methods=['GET'])
def get_history(count):
    conn = get_db_connection()
    readings = conn.execute(
        "SELECT * FROM dht_readings ORDER BY id DESC LIMIT ?", 
        (count,)
    ).fetchall()
    conn.close()

    history = [dict(row) for row in readings]
    return jsonify(history)

if __name__ == '__main__':
    print("Flask API running on http://127.0.0.1:5000")
    app.run(host='0.0.0.0', port=5000)
