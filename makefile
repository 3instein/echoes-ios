# Define download URLs
SCENE1_URL=https://drive.google.com/uc?export=download&id=1_Cdmk8AnOk5VmO-DVv1W9sshUUvpsHrh&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
SCENE2_URL=https://drive.google.com/uc?export=download&id=1ZhQZqTo96UF3wEt-ouLbK_qors5A0mCj&export=download&authuser=0&confirm=t&uuid=e29618d0-b802-41b5-b02d-6d85f40cf458&at=AN_67v1hqGCZzvCgLkXqc5Y4ei8P:1729324970252
SCENE4_URL=https://drive.google.com/uc?export=download&id=1_Cdmk8AnOk5VmO-DVv1W9sshUUvpsHrh&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
HOUSE_URL=https://drive.google.com/uc?export=download&id=1mH7ZiIb_RtlFrVCjLEgE6LgINuu7Q1Qa&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491

# Define target directory to store the downloaded scenes
SCENES_DIR=echoes/Scenes

# Default target
all: download_scenes

# Create the scenes directory if it doesn't exist
$(SCENES_DIR):
	mkdir -p $(SCENES_DIR)

# Rule to download all scenes
download_scenes: $(SCENES_DIR)
	@echo "Downloading Scene 1..."
	@curl -L -o $(SCENES_DIR)/scene1.scn "$(SCENE1_URL)"
	@echo "Downloading Scene 2..."
	@gdown -O $(SCENES_DIR)/scene2.scn "${SCENE2_URL}"
	@echo "Downloading Scene 4..."
	@curl -L -o $(SCENES_DIR)/scene4.scn "$(SCENE4_URL)"
	@echo "Downloading House..."
	@curl -L -o $(SCENES_DIR)/house.scn "$(HOUSE_URL)"
	@echo "All scenes downloaded!"

# Clean all scenes - remove the scenes directory
clean:
	rm -rf $(SCENES_DIR)
	@echo "Cleaned up all scenes."

# Clean one specific scene (e.g., make cleanOne scene=1)
cleanOne:
	rm -f $(SCENES_DIR)/Scene\ $(scene).scn
	@echo "Cleaned up Scene $(scene)."

# Help target to show available commands
help:
	@echo "Available targets:"
	@echo "  make              - Download all scenes"
	@echo "  make clean        - Remove all scenes"
	@echo "  make cleanOne scene=<scene number> - Remove a specific scene"
	@echo "  make help         - Show this help message"