from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
import secrets

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///database.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
bcrypt = Bcrypt(app)

# --- MODELOS ---
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    token = db.Column(db.String(100), unique=True) # Almacena la sesión actual

class Item(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(200))

with app.app_context():
    db.create_all()

# --- ENDPOINTS DE AUTENTICACIÓN ---
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'error': 'Faltan datos'}), 400
    
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': 'Usuario ya existe'}), 400

    hashed_pw = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    new_user = User(username=data['username'], password_hash=hashed_pw)
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify({'mensaje': 'Usuario registrado exitosamente'}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    user = User.query.filter_by(username=data.get('username')).first()
    
    if user and bcrypt.check_password_hash(user.password_hash, data.get('password')):
        token = secrets.token_hex(16)
        user.token = token
        db.session.commit()
        return jsonify({'mensaje': 'Login exitoso', 'token': token}), 200
        
    return jsonify({'error': 'Credenciales invalidas'}), 401

# --- MIDDLEWARE PARA SESIONES ---
def verificar_token(req):
    token = req.headers.get('Authorization')
    if not token:
        return None
    return User.query.filter_by(token=token).first()

# --- ENDPOINTS CRUD PROTEGIDOS ---
@app.route('/items', methods=['POST', 'GET'])
def handle_items():
    if not verificar_token(request):
        return jsonify({'error': 'No autorizado. Falta token.'}), 401
        
    if request.method == 'POST':
        data = request.get_json()
        nuevo_item = Item(name=data['name'], description=data.get('description', ''))
        db.session.add(nuevo_item)
        db.session.commit()
        return jsonify({'mensaje': 'Item creado', 'id': nuevo_item.id}), 201
        
    elif request.method == 'GET':
        items = Item.query.all()
        return jsonify([{'id': i.id, 'name': i.name, 'description': i.description} for i in items]), 200

@app.route('/items/<int:item_id>', methods=['PUT', 'DELETE'])
def handle_item_detail(item_id):
    if not verificar_token(request):
        return jsonify({'error': 'No autorizado'}), 401
        
    item = Item.query.get(item_id)
    if not item:
        return jsonify({'error': 'Item no encontrado'}), 404
        
    if request.method == 'PUT':
        data = request.get_json()
        item.name = data.get('name', item.name)
        item.description = data.get('description', item.description)
        db.session.commit()
        return jsonify({'mensaje': 'Item actualizado'}), 200
        
    elif request.method == 'DELETE':
        db.session.delete(item)
        db.session.commit()
        return jsonify({'mensaje': 'Item eliminado'}), 200

@app.route('/', methods=['GET'])
def index():
    return jsonify({"estado": "API REST Practica 5 en linea"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)