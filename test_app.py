import pytest
from app import app, todos


@pytest.fixture
def client():
    todos.clear()
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_create_and_list(client):
    r = client.post("/todos", json={"title": "Apprendre Jenkins"})
    assert r.status_code == 201
    r = client.get("/todos")
    assert len(r.get_json()) == 1


def test_create_without_title(client):
    r = client.post("/todos", json={})
    assert r.status_code == 400


def test_update_todo(client):
    todo = client.post("/todos", json={"title": "Docker"}).get_json()
    r = client.put(f"/todos/{todo['id']}", json={"done": True})
    assert r.status_code == 200
    assert r.get_json()["done"] is True


def test_delete_todo(client):
    todo = client.post("/todos", json={"title": "Git"}).get_json()
    r = client.delete(f"/todos/{todo['id']}")
    assert r.status_code == 204
    r = client.delete(f"/todos/{todo['id']}")
    assert r.status_code == 404