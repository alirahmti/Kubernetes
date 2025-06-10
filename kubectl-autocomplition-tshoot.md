## 🚀 Troubleshooting `root@master:~# kubectl cre_get_comp_words_by_ref: command not found` ❌

If you encounter the error:

```

# kubectl cre\_get\_comp\_words\_by\_ref: command not found
^C
````

It typically means that the `kubectl` autocompletion is not properly set up. Here's how to fix it:

## 1️⃣ Install the `bash-completion` Package 🔑

1. **Install the `bash-completion` package:**

   On **Debian/Ubuntu**-based systems, run the following command:

```bash
   sudo apt-get install bash-completion
````

For **Red Hat/CentOS** systems, use:

```bash
sudo yum install bash-completion
```

2. **Load the `bash-completion` configuration:**

   After installation, load the `bash-completion` configuration with the following command:

   ```bash
   source /etc/profile.d/bash_completion.sh
   ```

---

## 2️⃣ Enable `kubectl` Autocompletion ⚙️

1. **Activate `kubectl` autocompletion:**

   Run the following command to activate `kubectl` autocompletion for the current session:

   ```bash
   source <(kubectl completion bash)
   ```

---

## 3️⃣ Make Autocompletion Persistent 💾

To ensure `kubectl` autocompletion is always available, you need to add it to your shell’s configuration file:

1. **Add the autocompletion command to `~/.bashrc`:**

   Run the following command to make `kubectl` autocompletion persistent across sessions:

   ```bash
   echo 'source <(kubectl completion bash)' >> ~/.bashrc
   ```

2. **Reload your `~/.bashrc` file:**

   To apply the changes, run:

   ```bash
   source ~/.bashrc
   ```

---

## 4️⃣ Test `kubectl` Autocompletion ✅

Once you’ve completed the above steps, test the autocompletion feature:

* Type `kubectl` and press `Tab`. You should see a list of available commands and options!

---



### Key Notes:
- **Installation of `bash-completion`**: We install the required package for autocompletion functionality.
- **Enabling `kubectl` autocompletion**: Activates it for the current session and then makes it permanent by adding it to `~/.bashrc`.
- **Testing**: Verifying that autocompletion works by pressing `Tab` after typing `kubectl`.

---
## **Author** ✍️

Created by [Ali Rahmati](https://github.com/alirahmti). If you find this repository helpful, feel free to fork it or contribute!
