from flask import Flask, request, jsonify, send_file
from pytube import YouTube
import os
from werkzeug.utils import secure_filename
from pyngrok import ngrok

app = Flask(__name__)
app.config['DOWNLOAD_FOLDER'] = 'downloads/'
os.makedirs(app.config['DOWNLOAD_FOLDER'], exist_ok=True)

# Set up ngrok tunnel
public_url = ngrok.connect(5000).public_url
print(f" * ngrok tunnel: {public_url}")

@app.route('/download', methods=['POST'])
def download():
    try:
        data = request.get_json()
        url = data['url']
        format_type = data.get('format', 'mp4')
        
        yt = YouTube(url)
        
        if format_type == 'mp4':
            stream = yt.streams.get_highest_resolution()
            filename = f"{secure_filename(yt.title)}.mp4"
        else:
            stream = yt.streams.get_audio_only()
            filename = f"{secure_filename(yt.title)}.mp3"
            
        filepath = os.path.join(app.config['DOWNLOAD_FOLDER'], filename)
        stream.download(output_path=app.config['DOWNLOAD_FOLDER'], filename=filename)
        
        return jsonify({
            'status': 'success',
            'title': yt.title,
            'filename': filename,
            'download_url': f"{public_url}/download_file/{filename}"
        })
        
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 400

@app.route('/download_file/<filename>')
def download_file(filename):
    return send_file(
        os.path.join(app.config['DOWNLOAD_FOLDER'], filename),
        as_attachment=True
    )

if __name__ == '__main__':
    app.run(port=5000)।
