# GitHub Pages Hosting Guide for CSAE Policy

## 🎯 Goal
Host the CSAE policy page at: `https://www.nookly.app/csae-policy`

## 📋 Prerequisites
- GitHub account
- Access to your domain `nookly.app`
- Basic knowledge of Git

---

## 🚀 Step-by-Step Implementation

### Step 1: Create a GitHub Repository

1. **Go to GitHub.com** and sign in
2. **Click "New repository"** (green button)
3. **Repository settings:**
   - **Repository name**: `nookly-website` (or `nookly-app`)
   - **Description**: `Nookly Dating App Website`
   - **Visibility**: Public
   - **Initialize with**: Add a README file
4. **Click "Create repository"**

### Step 2: Upload the CSAE Policy File

#### Option A: Using GitHub Web Interface (Recommended for beginners)

**Step 2.1: Navigate to your repository**
1. After creating the repository, you'll be on the main page
2. You should see a list of files (including README.md)

**Step 2.2: Upload the CSAE policy file**
1. **Look for the "Add file" button** (it's a green button with a plus icon)
2. **Click "Add file"** → **"Upload files"**
3. **Drag and drop** the `csae_policy.html` file from your computer
4. **OR click "choose your files"** and browse to select the file

**Step 2.3: Rename the file**
1. **In the file upload area**, you'll see the uploaded file
2. **Click on the filename** `csae_policy.html`
3. **Change it to**: `csae-policy.html` (note the hyphen instead of underscore)
4. **This is important** because the URL will be `www.nookly.app/csae-policy`

**Step 2.4: Commit the file**
1. **Scroll down** to the bottom of the page
2. **Add a commit message**: `Add CSAE policy page`
3. **Click "Commit changes"** (green button)

**Step 2.5: Upload the index.html file**
1. **Click "Add file"** → **"Upload files"** again
2. **Upload** the `index.html` file
3. **Keep the name as**: `index.html`
4. **Add commit message**: `Add redirect index page`
5. **Click "Commit changes"**

**Step 2.6: Create the CNAME file**
1. **Click "Add file"** → **"Create new file"**
2. **File name**: `CNAME` (all caps, no extension)
3. **In the file content area**, type exactly:
   ```
   www.nookly.app
   ```
4. **Add commit message**: `Add custom domain CNAME`
5. **Click "Commit changes"**

#### Option B: Using Git Commands (For advanced users)
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/nookly-website.git
cd nookly-website

# Copy the CSAE policy file
cp /path/to/csae_policy.html csae-policy.html

# Add and commit
git add csae-policy.html
git commit -m "Add CSAE policy page"
git push origin main
```

### Step 3: Enable GitHub Pages

1. **Go to your repository** on GitHub
2. **Click "Settings"** tab (it's in the top navigation bar)
3. **Scroll down to "Pages"** section (in left sidebar)
4. **Under "Source"**, select **"Deploy from a branch"**
5. **Branch**: Select `main` (or `master`)
6. **Folder**: Select `/ (root)`
7. **Click "Save"**

### Step 4: Configure Custom Domain

1. **In the Pages settings**, find **"Custom domain"** section
2. **Enter your domain**: `www.nookly.app`
3. **Check "Enforce HTTPS"** (recommended)
4. **Click "Save"**

### Step 5: Create CNAME File

1. **In your repository**, click **"Add file" → "Create new file"**
2. **File name**: `CNAME`
3. **Content**: 
   ```
   www.nookly.app
   ```
4. **Commit the file**

### Step 6: Configure DNS Settings

**In your domain registrar (where you bought nookly.app):**

#### Add DNS Records:
```
Type: CNAME
Name: www
Value: YOUR_USERNAME.github.io
TTL: 3600 (or default)
```

#### Example:
```
Type: CNAME
Name: www
Value: manasa.github.io
TTL: 3600
```

### Step 7: Create Index Page (Optional)

Create a simple index page to redirect to your main website:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Nookly - Redirecting...</title>
    <meta http-equiv="refresh" content="0; url=https://nookly.app">
</head>
<body>
    <p>Redirecting to <a href="https://nookly.app">Nookly</a>...</p>
</body>
</html>
```

---

## 🔧 Alternative: Subdomain Approach

If you prefer `csae-policy.nookly.app`:

### Step 1: Create Subdomain Repository
- **Repository name**: `csae-policy.nookly.app`
- **Upload**: `csae_policy.html` as `index.html`

### Step 2: Configure DNS
```
Type: CNAME
Name: csae-policy
Value: YOUR_USERNAME.github.io
TTL: 3600
```

### Step 3: Custom Domain
- **Custom domain**: `csae-policy.nookly.app`

---

## 📁 Recommended File Structure

```
nookly-website/
├── README.md
├── CNAME
├── index.html (redirect to main site)
├── csae-policy.html (your CSAE policy)
└── assets/
    ├── css/
    └── images/
```

---

## ⏱️ Timeline

### Immediate (5-10 minutes):
- Create GitHub repository
- Upload CSAE policy file
- Enable GitHub Pages

### DNS Propagation (24-48 hours):
- Configure DNS settings
- Wait for propagation
- Test the URL

### Final Setup (1-2 hours):
- Test all links
- Verify mobile responsiveness
- Submit to Google Play Store

---

## 🧪 Testing Your Setup

### 1. Test the URL
```
https://www.nookly.app/csae-policy
```

### 2. Test Email Links
- Click "Report Safety Issue" button
- Click "General Support" button
- Verify they open email client with correct addresses

### 3. Test Mobile Responsiveness
- Open on mobile device
- Check all elements display correctly
- Test navigation and buttons

### 4. Test External Links
- NCMEC Hotline: 1-800-THE-LOST
- CyberTipline: www.cybertipline.org

---

## 🔍 Troubleshooting

### Common Issues:

#### 1. **Page Not Loading**
- Check DNS propagation (can take 24-48 hours)
- Verify CNAME record is correct
- Check GitHub Pages is enabled

#### 2. **HTTPS Issues**
- Enable "Enforce HTTPS" in GitHub Pages settings
- Wait for SSL certificate to be issued

#### 3. **Custom Domain Not Working**
- Verify CNAME file exists in repository
- Check DNS settings in domain registrar
- Ensure no conflicting DNS records

#### 4. **File Not Found**
- Check file name matches URL exactly
- Verify file is in the correct branch
- Check GitHub Pages source settings

---

## 📞 Support Resources

### GitHub Pages Documentation:
- [GitHub Pages Guide](https://pages.github.com/)
- [Custom Domain Setup](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)

### DNS Help:
- Contact your domain registrar's support
- Use DNS lookup tools (nslookup, dig)

---

## ✅ Final Checklist

- [ ] GitHub repository created
- [ ] CSAE policy file uploaded
- [ ] GitHub Pages enabled
- [ ] Custom domain configured
- [ ] CNAME file created
- [ ] DNS settings updated
- [ ] URL tested and working
- [ ] Email links tested
- [ ] Mobile responsiveness verified
- [ ] Ready for Google Play Store submission

---

## 🎉 Success!

Once completed, your CSAE policy will be available at:
```
https://www.nookly.app/csae-policy
```

This URL can be submitted to Google Play Store for CSAE compliance! 🚀
