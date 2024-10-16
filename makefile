# Define variables for file download links (replace with actual file IDs)
SCENE1_ID=YOUR_FILE_ID_1
SCENE2_ID=YOUR_FILE_ID_2

# Define download URLs
SCENE1_URL=https://drive.google.com/uc?export=download&id=1_Cdmk8AnOk5VmO-DVv1W9sshUUvpsHrh&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
SCENE2_URL=https://drive.google.com/uc?export=download&id=1GWXm7IIy87CYizBZkt4a9HAnNUZmqQid&export=download&authuser=0&confirm=t&uuid=6e235890-6285-47fa-8463-82f5ec86a99c&at=AN_67v233D7ZczqpYMBqh31dbPRd:1729044107981
# SCENE3_URL=https://drive.google.com/uc?export=download&id=1_Cdmk8AnOk5VmO-DVv1W9sshUUvpsHrh&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
SCENE4_URL=https://drive.google.com/uc?export=download&id=1_Cdmk8AnOk5VmO-DVv1W9sshUUvpsHrh&export=download&authuser=0&confirm=t&uuid=eee07aef-dff2-4f4f-89d9-5b1fe3d7cbf7&at=AN_67v3YwVEkLSElXT3J49tozP57:1729044061491
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
	# rename the file to Scene 1.scn
	@mv $(SCENES_DIR)/scene1.scn $(SCENES_DIR)/Scene\ 1.scn
	@echo "Downloading Scene 2..."
	@curl -L -o $(SCENES_DIR)/scene2.scn "$(SCENE2_URL)"
	# rename the file to Scene 2.scn
	@mv $(SCENES_DIR)/scene2.scn $(SCENES_DIR)/Scene\ 2.scn
	@echo "Downloading Scene 4..."
	@curl -L -o $(SCENES_DIR)/scene4.scn "$(SCENE4_URL)"
	# rename the file to Scene 4.scn
	@mv $(SCENES_DIR)/scene4.scn $(SCENES_DIR)/Scene\ 4.scn
	@echo "All scenes downloaded!"

# Clean target (optional) - remove the scenes directory
clean:
	rm -rf $(SCENES_DIR)
	@echo "Cleaned up the scenes."

# Add more targets as needed
