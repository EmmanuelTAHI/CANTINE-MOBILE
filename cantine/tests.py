from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone

from .models import Classe, Eleve, MenuJournalier, UserProfile


class AdminDashboardViewTests(TestCase):
    def setUp(self):
        User = get_user_model()
        self.user = User.objects.create_user(
            username="admin",
            email="admin@example.com",
            password="password123",
        )
        profile = self.user.profile
        profile.role = UserProfile.Role.ADMIN
        profile.save()

        login_success = self.client.login(username="admin", password="password123")
        self.assertTrue(login_success)

        self.classe = Classe.objects.create(nom="6ème A", niveau="Collège")
        self.eleve = Eleve.objects.create(
            matricule="HEG-001",
            nom="Diallo",
            prenom="Aissatou",
            classe=self.classe,
        )

    def test_dashboard_page_renders(self):
        response = self.client.get(reverse("cantine:admin_dashboard"))
        self.assertEqual(response.status_code, 200)
        self.assertIn("students", response.context)
        self.assertIn(self.eleve, response.context["students"])

    def test_admin_cannot_create_menu(self):
        payload = {
            "action": "create_menu_daily",
            "date": timezone.localdate().isoformat(),
            "plat_principal": "Riz au poisson",
        }
        response = self.client.post(
            reverse("cantine:admin_dashboard"),
            data=payload,
        )
        self.assertEqual(response.status_code, 302)
        self.assertFalse(
            MenuJournalier.objects.filter(
                plat_principal="Riz au poisson", date=timezone.localdate()
            ).exists()
        )


class LoginFlowTests(TestCase):
    def setUp(self):
        User = get_user_model()
        self.admin = User.objects.create_user(
            username="gestion",
            email="gestion@example.com",
            password="secretpass",
        )
        profile = self.admin.profile
        profile.role = UserProfile.Role.ADMIN
        profile.save()

    def test_login_redirects_to_admin_dashboard(self):
        response = self.client.post(
            reverse("cantine:login"),
            data={
                "username": "gestion",
                "password": "secretpass",
            },
            follow=True,
        )
        self.assertTrue(response.redirect_chain)
        final_url = response.redirect_chain[-1][0]
        self.assertIn("/espace-admin/dashboard/", final_url)
        self.assertContains(response, "Tableau de bord centralisé")
