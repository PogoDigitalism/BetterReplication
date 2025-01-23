import os

def rename_lua_to_luau_recursively(folder_path):
    for root, _, files in os.walk(folder_path):
        for file_name in files:
            full_path = os.path.join(root, file_name)
            if file_name.endswith('.lua'):
                new_file_name = file_name[:-4] + '.luau'
                new_full_path = os.path.join(root, new_file_name)
                os.rename(full_path, new_full_path)

folder_path = "."
rename_lua_to_luau_recursively(folder_path)
