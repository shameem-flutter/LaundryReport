# Laundry Application
 


## 🧰 Git User Manual

### 🚀 Getting Started

#### 🔄 Default Branch
```bash
    git checkout Development
```

---

## 🧪 Branching Strategy

We follow a structured branching model with the following types:

- [x] **Development** – Default working branch  
- [x] **feature/** – For adding new features  
- [x] **bugfix/** – For fixing identified bugs  
- [x] **release/** – For releasing stable builds  

![Branch Workflow](https://raw.githubusercontent.com/git-guides/git-flow/main/images/git-flow-branches.png)

---

## ✨ Adding a New Feature
```bash
    # Step 1: Checkout the default branch
        git checkout Development
        git pull

    # Step 2: Create a new feature branch
        git checkout -b feature/short-feature-name

    # Step 3: Write your code and commit
        git add -A
        git commit -m "Added: short description"

    # Step 4: Push and create Merge Request
        git push origin feature/short-feature-name
```

➡ Go to **GitLab ➝ Merge Requests ➝ New Merge Request**  
➡ Choose your source branch (`feature/short-feature-name`) and target branch (`Development`)  
➡ Fill in the title and description

**Then:**
- 🧑‍💼 **Select a Reviewer** from the dropdown list (person who will review your code)
- 🙋 **Assign Yourself** in the **Assignee** dropdown

➡ Click **Submit Merge Request**

➡ Wait for **Maintainer approval and merge**

```bash
    # Step 5: After merge, update local Development branch
        git checkout Development
        git pull
```

---

## 🐞 Fixing a Bug
```bash
    # Step 1: Checkout the default branch
        git checkout Development
        git pull
    
    # Step 2: Create a new bugfix branch
        git checkout -b bugfix/short-bug-name
    
    # fix the issue...

    # Step 3: Write your code and commit
        git add -A
        git commit -m "Fix: short description of bug fix"
        
    # Step 4: Push and create Merge Request
        git push origin bugfix/short-bug-name
```

➡ Go to **GitLab ➝ Merge Requests ➝ New Merge Request**  
➡ Choose your source branch (`bugfix/short-bug-name`) and target branch (`Development`)  
➡ Fill in the title and description

**Then:**
- 🧑‍💼 **Select a Reviewer** from the dropdown list (person who will review your code)
- 🙋 **Assign Yourself** in the **Assignee** dropdown

➡ Click **Submit Merge Request**

➡ Wait for **Maintainer approval and merge**

```bash
    # Step 5: After merge, update local Development branch
        git checkout Development
        git pull
```

---

## 🚢 Creating a Release
#### Only maintainer have permissions to go with this step
```bash
    # Step 1: Checkout the default branch
        git checkout Development
        git pull
    
    # Step 2: Create a new release branch
        git checkout -b release/1.0.0
        
        # ensure no pending bugs
        
    # Step 3: If no bugs in your code then commit
        git add -A
        git commit -m "Release: version 1.0.0"

    # Step 4: Push and create Merge Request
        git push origin release/1.0.0
```


---

## 🔁 Merge Request Flow

| Action | Who |
|--------|-----|
| Create MR | Developer |
| Review + Approve | Maintainer |
| Merge | Maintainer |
| Pull latest changes | Developer (post-merge) |

✅ Developers cannot push directly to protected branches (`Development`, `Production`, etc.)  
✅ Only Maintainers can approve and merge MRs.

---


## 📌 Best Practices

- Always pull the latest `Development` before creating new branches
- Keep commit messages meaningful and concise
- Use Merge Requests for **all changes**
- Do **not force push** to protected branches

## ⚠️ Important

**One Branch = One Task**

- Do **not** work on multiple tasks in the same branch.
- Every feature, bug fix, or improvement must have its **own dedicated branch**.
- Complete **one task → Create Merge Request → Get it reviewed & merged → Pull the latest `Development` → Create a new branch for the next task**.
- Keeping each branch focused makes Merge Requests meaningful, simplifies code reviews, testing, and future maintenance.


---


### 🙌 Final Note

> **"Every line of code you write shapes the future of this project. Let's build with purpose, review with care, and grow together as a team of excellence. Your contribution matters — not just to the repo, but to the mission behind it."**

**Happy coding, and keep making magic with your commits!**  
— Maintained with care by **The Febno Technologies Team** <img src="https://www.api.febno.com/uploads/logo_1_09eb3f551f.webp" alt="Febno Technologies" width="22" valign="middle">