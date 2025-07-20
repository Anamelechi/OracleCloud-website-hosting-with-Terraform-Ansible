// Smooth scroll for navigation links
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener("click", function (e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute("href"));
      if (target) {
        target.scrollIntoView({
          behavior: "smooth",
          block: "start",
        });
      }
    });
  });
  
  // Intersection Observer for scroll animations
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("visible");
          entry.target.style.opacity = "1";
          entry.target.style.transform = "translateY(0)";
        }
      });
    },
    { threshold: 0.1 }
  );
  
  document.querySelectorAll(".slide-up, .fade-in").forEach((el) => {
    observer.observe(el);
  });
  
  // Theme Persistence and Toggle
  const savedTheme = localStorage.getItem("theme") || "light";
  document.documentElement.setAttribute("data-theme", savedTheme);
  
  document.getElementById("themeToggle").addEventListener("click", () => {
    const currentTheme = document.documentElement.getAttribute("data-theme");
    const newTheme = currentTheme === "dark" ? "light" : "dark";
    document.documentElement.setAttribute("data-theme", newTheme);
    localStorage.setItem("theme", newTheme);
  });
  
  // Share Modal and Share Options Initialization
  (function initShareModal() {
    function setupShareModal() {
      const shareBtn = document.getElementById("shareBtn");
      const shareModal = document.getElementById("shareModal");
      const closeModal = document.getElementById("closeModal");
  
      if (shareBtn && shareModal && closeModal) {
        shareBtn.addEventListener("click", () => {
          console.log("Share button clicked");
          shareModal.style.display = "block";
        });
  
        closeModal.addEventListener("click", () => {
          console.log("Close button clicked");
          shareModal.style.display = "none";
        });
  
        // Close modal if clicked outside the modal content
        window.addEventListener("click", (e) => {
          if (e.target === shareModal) {
            shareModal.style.display = "none";
          }
        });
      } else {
        console.error("Share Modal elements not found");
      }
  
      // Base share text and URL
      const shareText = `Check out my Cloud Engineer Portfolio by Anamelechi Philip Njoku: ${window.location.href}`;
  
      // LinkedIn Share
      const shareLinkedIn = document.getElementById("shareLinkedIn");
      if (shareLinkedIn) {
        shareLinkedIn.addEventListener("click", (e) => {
          e.preventDefault();
          const url = `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(
            window.location.href
          )}`;
          window.open(url, "_blank");
        });
      }
  
      // Instagram Share (Copy link to clipboard)
      const shareInstagram = document.getElementById("shareInstagram");
      if (shareInstagram) {
        shareInstagram.addEventListener("click", (e) => {
          e.preventDefault();
          navigator.clipboard.writeText(window.location.href).then(() => {
            alert("Profile link copied! Share it on Instagram.");
          });
        });
      }
  
      // WhatsApp Share
      const shareWhatsApp = document.getElementById("shareWhatsApp");
      if (shareWhatsApp) {
        shareWhatsApp.addEventListener("click", (e) => {
          e.preventDefault();
          const url = `https://api.whatsapp.com/send?text=${encodeURIComponent(
            shareText
          )}`;
          window.open(url, "_blank");
        });
      }
  
      // SMS Share
      const shareSMS = document.getElementById("shareSMS");
      if (shareSMS) {
        shareSMS.addEventListener("click", (e) => {
          e.preventDefault();
          const url = `sms:?body=${encodeURIComponent(shareText)}`;
          window.location.href = url;
        });
      }
  
      // Email Share
      const shareEmail = document.getElementById("shareEmail");
      if (shareEmail) {
        shareEmail.addEventListener("click", (e) => {
          e.preventDefault();
          const subject = encodeURIComponent("My Cloud Engineer Portfolio");
          const url = `mailto:?subject=${subject}&body=${encodeURIComponent(
            shareText
          )}`;
          window.location.href = url;
        });
      }
    }
  
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", setupShareModal);
    } else {
      setupShareModal();
    }
  })();
  
  // PDF Download Functionality
  document.getElementById("downloadBtn").addEventListener("click", function () {
    const pdfUrl = "resume.pdf"; // Ensure resume.pdf is in your root directory
  
    // Create temporary link element for download
    const link = document.createElement("a");
    link.href = pdfUrl;
    link.download = "Anamelechi_Njoku_CV.pdf";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  
    // Visual feedback for downloading
    this.classList.add("downloading");
    const originalText = this.innerHTML;
    this.innerHTML = "Downloading...";
    this.style.cursor = "wait";
  
    setTimeout(() => {
      this.innerHTML = originalText;
      this.style.cursor = "pointer";
      this.classList.remove("downloading");
    }, 2000);
  });
  