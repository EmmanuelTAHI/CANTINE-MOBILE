from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from django.utils.translation import gettext_lazy as _

User = get_user_model()


def upload_menu_journalier(instance, filename):
    date_part = instance.date.strftime("%Y/%m/%d") if instance.date else "non_date"
    return f"menus/journaliers/{date_part}/{filename}"


def upload_menu_mensuel(instance, filename):
    return f"menus/mensuels/{instance.annee}/{instance.mois}/{filename}"


def upload_avatar(instance, filename):
    return f"users/{instance.user_id}/avatar/{filename}"


def upload_eleve_photo(instance, filename):
    identifier = instance.matricule or instance.pk or "eleve"
    return f"eleves/{identifier}/photos/{filename}"


class Classe(models.Model):
    """Représente une classe ou un groupe pédagogique dans l'établissement."""

    nom = models.CharField(max_length=50, unique=True, help_text="Exemple : 6ème A")
    niveau = models.CharField(
        max_length=50,
        blank=True,
        help_text="Cycle ou niveau associé (ex: Collège, Lycée).",
    )
    responsable = models.CharField(
        max_length=100,
        blank=True,
        help_text="Nom du professeur principal ou personne référente.",
    )

    class Meta:
        ordering = ("nom",)
        verbose_name = "classe"
        verbose_name_plural = "classes"

    def __str__(self) -> str:
        return self.nom


class Eleve(models.Model):
    """Inscrit au service de cantine."""

    matricule = models.CharField(
        max_length=30,
        unique=True,
        help_text="Identifiant unique interne ou scolaire.",
    )
    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    classe = models.ForeignKey(
        Classe,
        on_delete=models.PROTECT,
        related_name="eleves",
    )
    date_inscription = models.DateField(default=timezone.now)
    actif = models.BooleanField(
        default=True,
        help_text="Indique si l'élève est actuellement inscrit au service de cantine.",
    )
    contact_parent = models.CharField(
        max_length=50,
        blank=True,
        help_text="Téléphone du parent ou tuteur.",
    )
    email_parent = models.EmailField(blank=True)
    notes = models.TextField(blank=True)
    photo = models.ImageField(upload_to=upload_eleve_photo, blank=True, null=True)

    class Meta:
        ordering = ("nom", "prenom")
        verbose_name = "élève"
        verbose_name_plural = "élèves"

    def __str__(self) -> str:
        return f"{self.prenom} {self.nom}".strip()

    @property
    def telephone_parent(self) -> str:
        return self.contact_parent


class AbonnementCantine(models.Model):
    """Suivi de l'abonnement et du statut de cantine pour chaque élève."""

    class Statut(models.TextChoices):
        ACTIF = "actif", _("Actif")
        EN_ATTENTE = "en_attente", _("En attente")
        SUSPENDU = "suspendu", _("Suspendu")
        TERMINE = "termine", _("Terminé")

    eleve = models.OneToOneField(
        Eleve,
        on_delete=models.CASCADE,
        related_name="abonnement",
    )
    statut = models.CharField(
        max_length=15,
        choices=Statut.choices,
        default=Statut.ACTIF,
    )
    date_debut = models.DateField(default=timezone.now)
    date_fin = models.DateField(null=True, blank=True)
    solde = models.DecimalField(
        max_digits=9,
        decimal_places=2,
        default=0,
        help_text="Solde positif = crédit disponible, négatif = montant dû.",
    )
    montant_mensuel = models.DecimalField(
        max_digits=9,
        decimal_places=2,
        default=0,
        help_text="Montant facturé mensuellement pour ce forfait.",
    )

    class Meta:
        verbose_name = "abonnement cantine"
        verbose_name_plural = "abonnements cantine"

    def __str__(self) -> str:
        return f"Abonnement {self.eleve} ({self.get_statut_display()})"


class MenuJournalier(models.Model):
    """Planification des menus communiqués à la cantine."""

    date = models.DateField(unique=True)
    entree = models.CharField(max_length=150, blank=True)
    plat_principal = models.CharField(max_length=150)
    accompagnement = models.CharField(max_length=150, blank=True)
    dessert = models.CharField(max_length=150, blank=True)
    boisson = models.CharField(max_length=150, blank=True)
    commentaires = models.TextField(blank=True)
    photo = models.ImageField(
        upload_to=upload_menu_journalier,
        blank=True,
        help_text="Photo illustrative du menu du jour.",
    )

    class Meta:
        ordering = ("date",)
        verbose_name = "menu journalier"
        verbose_name_plural = "menus journaliers"

    def __str__(self) -> str:
        return f"Menu du {self.date:%d/%m/%Y}"


class MenuMensuel(models.Model):
    """Planification globale d'un mois donné avec aperçu visuel."""

    class Mois(models.IntegerChoices):
        JANVIER = 1, _("Janvier")
        FEVRIER = 2, _("Février")
        MARS = 3, _("Mars")
        AVRIL = 4, _("Avril")
        MAI = 5, _("Mai")
        JUIN = 6, _("Juin")
        JUILLET = 7, _("Juillet")
        AOUT = 8, _("Août")
        SEPTEMBRE = 9, _("Septembre")
        OCTOBRE = 10, _("Octobre")
        NOVEMBRE = 11, _("Novembre")
        DECEMBRE = 12, _("Décembre")

    titre = models.CharField(max_length=150)
    mois = models.IntegerField(choices=Mois.choices)
    annee = models.PositiveIntegerField(default=timezone.now().year)
    description = models.TextField(blank=True)
    couverture = models.ImageField(
        upload_to=upload_menu_mensuel,
        blank=True,
        help_text="Image de couverture pour présenter le menu du mois.",
    )
    document = models.FileField(
        upload_to=upload_menu_mensuel,
        blank=True,
        help_text="Fichier PDF ou document détaillant le menu.",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("mois", "annee")
        ordering = ("-annee", "-mois")
        verbose_name = "menu mensuel"
        verbose_name_plural = "menus mensuels"

    def __str__(self) -> str:
        return f"Menu {self.get_mois_display()} {self.annee}"


class PresenceRepas(models.Model):
    """Historique des présences quotidiennes enregistrées par le prestataire."""

    class TypeRepas(models.TextChoices):
        DEJEUNER = "dejeuner", _("Déjeuner")
        DINER = "diner", _("Dîner")

    eleve = models.ForeignKey(
        Eleve,
        on_delete=models.CASCADE,
        related_name="presences",
    )
    date = models.DateField(default=timezone.now)
    repas = models.CharField(
        max_length=20,
        choices=TypeRepas.choices,
        default=TypeRepas.DEJEUNER,
    )
    present = models.BooleanField(default=True)
    heure_pointage = models.TimeField(null=True, blank=True)
    commentaire = models.TextField(blank=True)
    menu = models.ForeignKey(
        "MenuJournalier",
        on_delete=models.SET_NULL,
        related_name="presences",
        null=True,
        blank=True,
    )

    class Meta:
        ordering = ("-date", "eleve__nom")
        verbose_name = "présence repas"
        verbose_name_plural = "présences repas"
        constraints = [
            models.UniqueConstraint(
                fields=("eleve", "date", "repas"),
                name="unique_presence_par_repas",
            )
        ]

    def __str__(self) -> str:
        return f"{self.eleve} - {self.date:%d/%m/%Y} ({self.get_repas_display()})"


class DepenseCantine(models.Model):
    """Dépenses journalières ou mensuelles saisies par le prestataire."""

    class Categorie(models.TextChoices):
        INGREDIENTS = "ingredients", _("Ingrédients")
        GAZ = "gaz", _("Gaz / énergie")
        MAIN_OEUVRE = "main_oeuvre", _("Main d'œuvre")
        LOGISTIQUE = "logistique", _("Logistique")
        AUTRE = "autre", _("Autre")

    libelle = models.CharField(max_length=120)
    categorie = models.CharField(
        max_length=20,
        choices=Categorie.choices,
        default=Categorie.INGREDIENTS,
    )
    montant = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateField(default=timezone.now)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ("-date", "libelle")
        verbose_name = "dépense cantine"
        verbose_name_plural = "dépenses cantine"

    def __str__(self) -> str:
        return f"{self.libelle} - {self.montant} GNF"


class UserProfile(models.Model):
    """Profil utilisateur interne pour distinguer administration et prestataire."""

    class Role(models.TextChoices):
        ADMIN = "admin", _("Administration")
        PRESTATAIRE = "prestataire", _("Prestataire")

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile",
    )
    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.ADMIN,
    )
    avatar = models.ImageField(
        upload_to=upload_avatar,
        blank=True,
        null=True,
        help_text="Photo de profil (affichage circulaire).",
    )
    contact = models.CharField(max_length=50, blank=True)
    poste = models.CharField(max_length=80, blank=True)
    bio = models.TextField(blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "profil utilisateur"
        verbose_name_plural = "profils utilisateurs"

    def __str__(self) -> str:
        return f"Profil {self.user.get_full_name() or self.user.username}"

    @property
    def telephone(self):
        return self.contact

    @property
    def entreprise(self):
        return self.poste


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    if created:
        default_role = (
            UserProfile.Role.ADMIN
            if instance.is_staff or instance.is_superuser
            else UserProfile.Role.PRESTATAIRE
        )
        UserProfile.objects.create(user=instance, role=default_role)
    else:
        instance.profile.save()
