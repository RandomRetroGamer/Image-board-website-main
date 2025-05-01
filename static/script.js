document.addEventListener('DOMContentLoaded', function () {
    const form = document.getElementById('uploadForm');
    if (!form) return;

    form.addEventListener('submit', function (e) {
        e.preventDefault();

        const title = document.getElementById('title').value;
        const description = document.getElementById('description').value;
        const file = document.getElementById('image').files[0];

        if (!file) return;

        const reader = new FileReader();

        reader.onload = () => {
            const imageURL = reader.result;
            addPost(title, description, imageURL);

            // Reset the form after the post is added
            document.getElementById('uploadForm').reset();
        };

        reader.readAsDataURL(file);
    });

    function addPost(title, description, imageURL) {
        const container = document.getElementById('postContainer');
        const post = document.createElement('div');
        post.className = 'post';

        post.innerHTML = `
            <h2>${title}</h2>
            <img src="${imageURL}" alt="${title}" style="max-width: 200px;" />
            <p>${description}</p>
        `;

        container.prepend(post); // Adds new post at the top
    }
});
function toggleComments(button) {
    const commentsSection = document.querySelector('.create_thread_container');

    if (!commentsSection) {
        console.error('No .create_thread_container found!');
        return;
    }

    if (commentsSection.style.display === 'none' || commentsSection.style.display === '') {
        commentsSection.style.display = 'block';
    } else {
        commentsSection.style.display = 'none';
    }
}

function toggle(button) {
    const commentSection = button.nextElementSibling;
    if (!commentSection || !commentSection.classList.contains('comment_section')) {
        console.error('Comment section not found next to button');
        return;
    }

    commentSection.style.display =
        (commentSection.style.display === 'none' || commentSection.style.display === '')
            ? 'block'
            : 'none';
}

document.querySelectorAll('.upvote-btn').forEach(button => {
    button.addEventListener('click', function (event) {
        event.preventDefault();

        const postID = this.dataset.postId;
        const voteCountElement = this.querySelector('.vote-count');

        console.log("Attempting to upvote post:", postID); // debug

        fetch(`/upvote/${postID}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            }
        })
            .then(response => {
                if (response.status === 204) {
                    this.style.backgroundColor = "orange";
                } else if (response.ok) {
                    this.style.backgroundColor = "orange";
                    return response.json();
                } else {
                    throw new Error('Upvote failed');
                }
            })
            .then(data => {
                if (data && data.upvotes !== undefined) {
                    voteCountElement.textContent = data.upvotes;
                }
            })
            .catch(error => {
                console.error("Error:", error);
                alert("Failed to upvote. Please try again.");
            });
    });
});


document.querySelectorAll('.downvote-btn').forEach(button => {
    button.addEventListener('click', function (event) {
        event.preventDefault(); // prevent form submission
        const postId = this.dataset.postId;

        fetch(`/downvote/${postId}`, {
            method: 'POST'
        })
            .then(response => {
                if (response.redirected) {
                    // reload only part of the page, or use location.href = response.url
                    location.reload(); // simple option, reloads but scrolls preserved
                }
            });
    });
});