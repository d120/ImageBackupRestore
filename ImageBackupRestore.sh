#!/bin/bash

hdd="/dev/sda"
imagefile_directory=""

imagefile_prefix="dekanat_laptop_image"
imagefile_suffix=".img.gz"

choice1="Backup: Save image of laptop's hard disk on stick."
choice2="Restore: Write saved image back to the laptop (WARNING: will overwrite hard disk!)."
choice3="Abort: Do nothing."

echo "=== Laptop Image: Backup & Restore ==="
echo ""

cd $imagefile_directory 2> /dev/null
if [[ $? != 0 ]]; then
    echo "ERROR: Cannot go to the directory where the images are: $imagefile_directory."
    echo "Aborting ..."
    exit 1
fi

echo "What do you want to do (choose number)?"
select choice in "$choice1" "$choice2" "$choice3"
do
    echo ""
    case $choice in
    $choice1)
        # BACKUP
        imagename=$imagefile_prefix'_'$(date +"%F_%H-%M-%S")$imagefile_suffix
        echo "A new backup with the name $imagename will be created."
        old_images=$(ls *$imagefile_suffix 2> /dev/null)
        num_old_images=$(echo $old_images | wc -w)
        if [[ $num_old_images != 0 ]]; then
            echo -n "The following $num_old_images old images will be removed to save space: "
            echo $old_images
        fi
        echo -n "Press any key to continue or Ctrl+C to abort:"
        read -n 1
        echo ""
        rm -rf $old_images
        dd if=$hdd bs=8M status=progress | gzip -c > $imagename
        if [[ ${PIPESTATUS[0]} != 0 || ${PIPESTATUS[1]} != 0 ]]; then
            echo ""
            echo "ERROR: An error occured during creation of the backup."
            echo "Aborting ..."
            exit 1
        fi
        echo ""
        echo "Please wait until all data is written..."
        sync
        echo "Backup successfully created."
        break
        ;;
    $choice2)
        # RESTORE
        image=$(ls -1r *$imagefile_suffix 2> /dev/null | head -n 1)
        if [[ "$image" == "" ]]; then
            echo "ERROR: Cannot find any $imagefile_suffix files in $imagefile_directory."
            echo "Aborting ..."
            exit 1
        fi
        echo "The image $image will be written to disk."
        echo "WARNING: This will overwrite the entire hard disk!"
        echo -n "Press any key to continue or Ctrl+C to abort:"
        read -n 1
        echo ""
        gunzip -c $image | dd of=$hdd bs=8M status=progress
        if [[ ${PIPESTATUS[0]} != 0 || ${PIPESTATUS[1]} != 0 ]]; then
            echo ""
            echo "ERROR: An error occured while restoring the image."
            echo "Aborting ..."
            exit 1
        fi
        echo ""
        echo "Please wait until all data is written..."
        sync
        echo "Image successfully restored."
        break
        ;;
    *)
        # ABORT
        echo "Aborting ..."
        break
        ;;
    esac
done
