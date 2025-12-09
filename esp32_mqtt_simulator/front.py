from flask import Flask, jsonify
import sqlite3

app = Flask(__name__)
DB_NAME = "sensor_data.db"

def get_db_connection():
    """Establishes a connection to the SQLite database."""
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row # Allows access to columns by name
    return conn

@app.route('/api/latest', methods=['GET'])
def get_latest_reading():
    """Returns the most recent sensor reading."""
    conn = get_db_connection()
    # Fetch the latest reading
    reading = conn.execute("SELECT * FROM dht_readings ORDER BY id DESC LIMIT 1").fetchone()
    conn.close()
    
    if reading is None:
        return jsonify({"message": "No data available"}), 404
        
    # Convert sqlite3.Row object to a dictionary for JSON serialization
    return jsonify(dict(reading))

@app.route('/api/history/<int:count>', methods=['GET'])
def get_history(count):
    """Returns the 'count' most recent sensor readings."""
    conn = get_db_connection()
    # Fetch the history
    readings = conn.execute(
        "SELECT * FROM dht_readings ORDER BY id DESC LIMIT ?", 
        (count,)
    ).fetchall()
    conn.close()

    # Convert list of Row objects to a list of dictionaries
    history = [dict(row) for row in readings]
    return jsonify(history)

if __name__ == '__main__':
    # You can change the port if needed
    app.run(host='0.0.0.0', port=5001)