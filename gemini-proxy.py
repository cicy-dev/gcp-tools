#!/usr/bin/env python3
"""Gemini API 代理服务"""
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)
API_KEY = 'AIzaSyC5EqHvfu0SJOKrvkPz8vH3E7iFr9ZW1c8'
BASE_URL = 'https://generativelanguage.googleapis.com/v1beta'

@app.route('/generate', methods=['POST'])
def generate():
    """生成内容"""
    data = request.json
    prompt = data.get('prompt', '')
    model = data.get('model', 'gemini-2.5-flash')
    
    response = requests.post(
        f'{BASE_URL}/models/{model}:generateContent?key={API_KEY}',
        json={'contents': [{'parts': [{'text': prompt}]}]},
        timeout=60
    )
    
    return jsonify(response.json())

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'location': 'gcp'})

if __name__ == '__main__':
    print('🚀 Gemini Proxy starting on http://0.0.0.0:8088')
    app.run(host='0.0.0.0', port=8088)
