#app.py // yes this is called main but its the app
#kinda built this using linux so idk how windows will handle this, i can recommend using windows visual studios just install flask and werkzeug.utils

from flask import Flask, render_template, request, redirect, url_for, abort
import os
import json # // adding module <<
from werkzeug.utils import secure_filename
import secrets

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'static/uploads'
app.config['MAX_CONTENT_LENGTH'] = 2 * 1024 * 1024  # 2MB max upload size
app.config['SECRET_KEY'] = secrets.token_hex(16)    # Randomly generated secret key


POSTS_FILE = 'posts.json'

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

def allowed_files(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# // functions // load post from files
def load_post():
    if os.path.exists(POSTS_FILE):
        with open(POSTS_FILE, 'r') as f:
            try:
                return json.load(f)
            except json.JSONDecodeError:
                return []  # falls back if file is corrupted //
    return []

# // saves post files to the files
def save_posts(posts):
    with open(POSTS_FILE, 'w') as f:
        json.dump(posts, f, indent=4 )

# // read file // starter file 
def read_file(file_path):
    try:
        file = open(file_path, 'r')
        content = file.read()
        print(content)
    except FileNotFoundError:
        print(f"Error: file not found at {file_path}")
    finally:
        # // file closes ... 
        if 'file' in locals():
            file.close()

read_file('readme.txt')

#// check json file
def fix_json():
    posts = load_post()
    changed= False

    for post in posts:
        if "comments" not in post:
            post["comments"] = []
            changed = True
    
    if changed:
        save_posts(posts)
        print('Fixed post')


# // main route
@app.route('/', methods=['GET', 'POST'])
def index():
    posts = load_post()  # <-- returns loaded from disk

    if request.method == 'POST':
        title = request.form['title']
        description = request.form['description']
        image = request.files['image']

        if not title or not description:
            abort(400, description="Title and description required.")

        if image and allowed_files(image.filename):
            filename = secure_filename(image.filename)
            path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            image.save(path)

            post = {
                'title': title,
                'description': description,
                'image': path,
                'comments': []
            }

            posts.insert(0, post)  # <-- insert the actual post, not the list itself
            save_posts(posts)
        else:
            abort(400, description="Invalid File Type.")


        return redirect(url_for('index'))  # // for the newest post // it resets

    return render_template('index.html', posts=posts)


@app.route('/comment/<int:post_id>', methods=['POST'])
def comment(post_id):
    posts = load_post()
    comment_text = request.form["comment"]

    if not comment_text:
        abort(400, description="Commnet text required! ")

    if 0 <= post_id < len(posts):
        posts[post_id].setdefault("comments", []).append(comment_text)
        save_posts(posts)
    else:
        abort(404)

    return redirect(url_for('index'))

if __name__ == "__main__":
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    app.run(debug=True)

#changed the upload folder to keep the images from repeating // changed structure of post append to commit changes faster

# // don't mess with the flask code! this code structure is senstive and is a bitch to work with!
