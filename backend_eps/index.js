const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Configuración de la conexión a MySQL en XAMPP
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',      // Usuario por defecto en XAMPP
    password: '',      // Contraseña por defecto vacía en XAMPP
    database: 'eps_citas_db',
    port: 3306
});

// Conectar a MySQL
db.connect((err) => {
    if (err) {
console.error('Error al conectar a MySQL en XAMPP:', err.message);
        return;
    }
    console.log('Servidor conectado exitosamente a MySQL (XAMPP).');
});

// Endpoint 1: Obtener todas las citas
app.get('/api/citas', (req, res) => {
    const query = 'SELECT * FROM citas ORDER BY fecha DESC';
    db.query(query, (err, results) => {
        if (err) {
            console.error('Error consultando la base de datos:', err);
            return res.status(500).json({ error: 'Error interno del servidor' });
        }
        res.json(results);
    });
});

// Endpoint 2: Obtener citas filtradas por estado (opcional)
app.get('/api/citas/estado/:estado', (req, res) => {
    const estadoParam = req.params.estado;
    const query = 'SELECT * FROM citas WHERE estado = ? ORDER BY fecha DESC';
    db.query(query, [estadoParam], (err, results) => {
        if (err) {
            console.error('Error filtrando la base de datos:', err);
            return res.status(500).json({ error: 'Error al filtrar citas' });
        }
        res.json(results);
    });
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Servidor HTTP ejecutándose en http://localhost:${PORT}`);
});
