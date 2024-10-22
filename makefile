# Define download URLs
SCENE1_URL=https://drive.google.com/uc?export=download&id=1_Cdmk8AnOk5VmO-DVv1W9sshUUvpsHrh&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
SCENE2_URL=https://drive.google.com/uc?export=download&id=1BW3iBSyg5D3tz1CBEiLr_ayigR8C2uj0&export=download&authuser=0&confirm=t&uuid=e29618d0-b802-41b5-b02d-6d85f40cf458&at=AN_67v1hqGCZzvCgLkXqc5Y4ei8P:1729324970252
SCENE3_URL=https://drive.google.com/uc?export=download&id=1so06ne9YJRDctFtp4eL71tR2p7gqzXC_&export=download&authuser=0&confirm=t&uuid=e29618d0-b802-41b5-b02d-6d85f40cf458&at=AN_67v1hqGCZzvCgLkXqc5Y4ei8P:1729324970252
SCENE4_URL=https://drive.google.com/uc?export=download&id=1FfQl9-SIj9orxuJORexGd7M0diUOEx5R&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
SCENE5_URL=https://drive.google.com/uc?export=download&id=1NBIr9nRiiGaSReV_imyFpqCAoVK5WR-r&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
SCENE6_URL=https://drive.google.com/uc?export=download&id=1e3vr2g9cWMy5JRtAP9QzE5s9QeNG4fre&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
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
	@echo "Downloading Scene 3..."
	@gdown -O $(SCENES_DIR)/scene3.scn "${SCENE3_URL}"
	@echo "Downloading Scene 4..."
	@curl -L -o $(SCENES_DIR)/scene4.scn "$(SCENE4_URL)"
	@echo "Downloading Scene 5..."
	@curl -L -o $(SCENES_DIR)/scene5.scn "$(SCENE5_URL)"
	@echo "Downloading Scene 6..."
	@curl -L -o $(SCENES_DIR)/scene6.scn "$(SCENE6_URL)"
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