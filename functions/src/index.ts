import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

admin.initializeApp();

interface Reservation {
  email: string;
  nom?: string;
  passagers?: number;
  vol?: string;
}

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_PASS,
  },
});

export const sendConfirmationEmail = onDocumentCreated(
    "reservations/{reservationId}",
    (event) => {
      const snapshot = event.data;
      if (!snapshot) {
        logger.error("No data associated with the event");
        return;
      }

      const data = snapshot.data() as Reservation;
      const reservationId = event.params.reservationId;

      const mailOptions = {
        from: `Vacancia Voyage <${process.env.GMAIL_USER}>`,
        to: data.email,
        subject: `Confirmation #${reservationId}`,
        html: `
        <div style="font-family: Arial;
         padding: 20px;
         max-width: 600px;">
          <h2 style="color: #2c3e50;
          ">Merci ${data.nom || "Client"} !</h2>
          <p>Votre réservation n°<strong>${reservationId}
          </strong> est confirmée.</p>
          
          <h3 style="color: #2c3e50;">Détails :</h3>
          <ul>
            <li>Date : ${new Date().toLocaleDateString("fr-FR")}</li>
            <li>Passagers : ${data.passagers || 1}</li>
            ${data.vol ? `<li>Vol : ${data.vol}</li>` : ""}
          </ul>
        </div>
        
      `,
      }
    ;

      return transporter.sendMail(mailOptions)
          .then(() => snapshot.ref.update({ emailSent: true }))
          .catch((error) => {
            logger.error("Erreur:", error);
            return snapshot.ref.update({
              emailError: error.message,
              emailSent: false
            });
          });
    }
);
