from django.contrib import admin
from django.contrib.auth import get_user_model
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import (
    AbonnementCantine,
    Classe,
    DepenseCantine,
    Eleve,
    MenuJournalier,
    MenuMensuel,
    PresenceRepas,
    UserProfile,
)


class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    fk_name = "user"
    fields = ("role", "contact", "poste", "avatar", "bio")


User = get_user_model()


class UserAdmin(BaseUserAdmin):
    inlines = (UserProfileInline,)

    def get_inline_instances(self, request, obj=None):
        if not obj:
            return []
        return super().get_inline_instances(request, obj)


try:
    admin.site.unregister(User)
except admin.sites.NotRegistered:
    pass

admin.site.register(User, UserAdmin)


@admin.register(Classe)
class ClasseAdmin(admin.ModelAdmin):
    list_display = ("nom", "niveau", "responsable")
    search_fields = ("nom", "niveau", "responsable")


@admin.register(Eleve)
class EleveAdmin(admin.ModelAdmin):
    list_display = (
        "matricule",
        "prenom",
        "nom",
        "classe",
        "actif",
        "date_inscription",
    )
    list_filter = ("actif", "classe")
    search_fields = ("matricule", "nom", "prenom")
    autocomplete_fields = ("classe",)
    ordering = ("nom", "prenom")


@admin.register(AbonnementCantine)
class AbonnementCantineAdmin(admin.ModelAdmin):
    list_display = (
        "eleve",
        "statut",
        "date_debut",
        "date_fin",
        "montant_mensuel",
        "solde",
    )
    list_filter = ("statut",)
    search_fields = ("eleve__nom", "eleve__prenom", "eleve__matricule")
    autocomplete_fields = ("eleve",)


@admin.register(MenuJournalier)
class MenuJournalierAdmin(admin.ModelAdmin):
    list_display = ("date", "plat_principal", "entree", "dessert")
    search_fields = ("plat_principal", "entree", "dessert")
    list_filter = ("date",)
    ordering = ("-date",)
    readonly_fields = ("photo",)


@admin.register(MenuMensuel)
class MenuMensuelAdmin(admin.ModelAdmin):
    list_display = ("titre", "mois_affiche", "annee", "created_at")
    list_filter = ("annee", "mois")
    search_fields = ("titre", "description")
    ordering = ("-annee", "-mois")

    @admin.display(description="Mois")
    def mois_affiche(self, obj):
        return obj.get_mois_display()


@admin.register(PresenceRepas)
class PresenceRepasAdmin(admin.ModelAdmin):
    list_display = ("date", "eleve", "repas", "present", "heure_pointage")
    list_filter = ("repas", "present", "date")
    search_fields = ("eleve__nom", "eleve__prenom", "eleve__matricule")
    autocomplete_fields = ("eleve",)
    ordering = ("-date",)


@admin.register(DepenseCantine)
class DepenseCantineAdmin(admin.ModelAdmin):
    list_display = ("libelle", "categorie", "montant", "date")
    list_filter = ("categorie", "date")
    search_fields = ("libelle",)


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "contact", "updated_at")
    list_filter = ("role",)
    search_fields = ("user__username", "user__email", "contact")
